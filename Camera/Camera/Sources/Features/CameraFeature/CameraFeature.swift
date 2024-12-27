import AVFoundation
import Combine
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class CameraModel {
  var buildNumber: Build.Version { Build.version }
  var destination: Destination? { didSet { self.bind() } }
  var navigationTitle = "00:00:00"
  var latestVideoThumbnail: UIImage?
  var recordingStartDate: Date?
  
  // Shared
  @ObservationIgnored @Shared(.camera) var camera
  @ObservationIgnored @Shared(.assetCollection) var assetCollection
  @ObservationIgnored @SharedReader(.userPermissions) var userPermissions
  
  // Dependencies
  @ObservationIgnored @Dependency(\.camera) var cameraClient
  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.uuid) var uuid
  @ObservationIgnored @Dependency(\.imageGenerator) var imageGenerator
  @ObservationIgnored @Dependency(\.continuousClock) var clock

  @dynamicMemberLookup
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
    case library(LibraryModel)
    case settings(SettingsModel)
  }
  
  // oop
  private static func formattedRecordingDuration(since startDate: Date) -> String {
    let now = Date() // Current date and time
    let elapsedTime = now.timeIntervalSince(startDate) // Time difference in seconds
    
    // Use DateComponentsFormatter to format the elapsed time
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second] // Use hours, minutes, and seconds
    formatter.unitsStyle = .positional // Ensures the "00:00:00" style
    formatter.zeroFormattingBehavior = .pad // Pads with leading zeros
    
    return formatter.string(from: elapsedTime) ?? "00:00:00"
  }
  
  var hasFullPermissions: Bool {
    self.userPermissions == .authorized
  }
  
  var isSwitchCameraButtonDisabled: Bool {
    self.camera.isRecording
  }
  
  func recordingButtonTapped() {
    !camera.isRecording ? self.startRecording() : self.stopRecording()
  }
  
  private func startRecording() {
    try? self.cameraClient.startRecording(self.movieFileOutput)
    self.recordingStartDate = .now
    self.$camera.isRecording.withLock { $0 = true }
  }
  
  private func stopRecording() {
    try? cameraClient.stopRecording()
    self.recordingStartDate = .none
    self.$camera.isRecording.withLock { $0 = false }
  }

  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func navigateCameraRoll() {
    self.destination = .library(LibraryModel())
  }
  
  func navigateSettings() {
    self.destination = .settings(SettingsModel())
  }
  
  func dismissSettingsButtonTapped() {
    self.destination = .none
  }

  func switchCameraButtonTapped() {
    _ = Result {
      let position = try self.cameraClient.switchCamera()
      self.$camera.position.withLock { $0 = position }
    }
  }
  
  func task() async {
    guard hasFullPermissions else {
      return
    }

    // @DEDA when you return, start the session again.
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        for await _ in await self.clock.timer(interval: .seconds(1)) {
          await MainActor.run {
            // update timer
            self.navigationTitle = Self.formattedRecordingDuration(
              since: self.recordingStartDate ?? .now
            )
          }
        }
      }
      taskGroup.addTask {
        // @DEDA you have to wait for MainModel to finish syncing the asset collection before you can continue. You will nuke MainModel soon.
        // also, this is supposed to be responsive.. after you finish recording.
        try? await Task.sleep(for: .seconds(1))
        guard let assetCollection = await self.assetCollection else {
          print("Asset collection was nil.")
          return
        }
        guard let fetchResult = try? await self.photos.fetchAssets(.lastVideo(in: assetCollection)) else {
          print("Fetch result failed.")
          return
        }
        guard let phAsset = fetchResult.lastObject else {
          print("PHAsset was nil.")
          return
        }
        guard let avAsset = (await self.photos.requestAVAsset(phAsset, .none)?.asset as? AVURLAsset) else {
          print("AVAsset was nil.")
          return
        }
        guard let imageThumbnail = try? await self.imageGenerator.image(avAsset)?.image else {
          print("Failed to generate image thumbnail")
          return
        }
        await MainActor.run {
          self.latestVideoThumbnail = UIImage(cgImage: imageThumbnail)
        }
      }
      taskGroup.addTask {
        try? await self.cameraClient.connect(self.camera.captureVideoPreviewLayer)
      }
      taskGroup.addTask {
        for await event in await self.cameraClient.events() {
          await self.handle(event)
        }
      }
    }
  }
}

// MARK: Private

private extension CameraModel {
  func bind() {
    switch destination {
      
    case let .userPermissions(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case let .library(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case let .settings(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case .none:
      break
    }
  }
  
  func handle(_ event: CameraClient.DelegateEvent) {
    switch event {
      
    case let .avCaptureFileOutputRecordingDelegate(.fileOutput(_, outputFileURL, _, _)):
      Task {
        if let assetCollection {
          try await self.photos.performChanges(
            .save(contentsOf: outputFileURL, to: assetCollection)
          )
        } else {
          print("@DEDA yo asset collection wuz nil.")
        }
      }
    }
  }
  
  var movieFileOutput: URL {
    URL.temporaryDirectory
      .appending(component: self.uuid().uuidString)
      .appendingPathExtension(for: .quickTimeMovie)
  }
}

// MARK: - SwiftUI

struct CameraView: View {
  @Bindable var model: CameraModel
  @State var count: Int?

  var body: some View {
    NavigationStack {
      self.content
        .task { await self.model.task() }
        .navigationBarBackButtonHidden()
        .overlay(content: self.overlay)
        .toolbar(content: self.toolbar)
        .sheet(item: $model.destination.userPermissions) { model in
          UserPermissionsSheet(model: model)
        }
        .fullScreenCover(item: $model.destination.library) { model in
          LibraryView(model: model)
        }
        .overlay(item: $model.destination.settings) { $model in
          SettingsView(model: model)
        }
    }
  }
  
  @MainActor private var content: some View {
    Group {
      if self.model.hasFullPermissions {
        self.cameraPreview.onTapGesture(count: 2) {
          self.model.switchCameraButtonTapped()
        }
      } else {
        self.permissionsRequired
      }
    }
  }
  
  @MainActor private func toolbar() -> some ToolbarContent {
    Group {
      ToolbarItem(placement: .topBarLeading) {
        Button(action: {}) {
          Image(systemName: "bolt.fill")
        }
      }
      ToolbarItem(placement: .principal) {
        Text(self.model.navigationTitle)
          .foregroundColor(.white)
          .fontWeight(.semibold)
          .background(Color.red.opacity(self.model.camera.isRecording ? 1 : 0))
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: self.model.navigateSettings) {
          Image(systemName: "ellipsis")
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Happy path") {
  let value: UserPermissions.State = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value
  
  CameraView(model: CameraModel())
}
