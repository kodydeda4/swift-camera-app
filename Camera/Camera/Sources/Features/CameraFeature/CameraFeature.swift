import AVFoundation
import Combine
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation
import CasePaths

@MainActor
@Observable
final class CameraModel {
  var buildNumber: Build.Version { Build.version }
  var destination: Destination? { didSet { self.bind() } }
  var navigationTitle = "00:00:00"
  var isRecording = false
  var latestVideoThumbnail: UIImage?
  var recordingStartDate: Date?
  var captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()

  // Shared
  @ObservationIgnored @Shared(.assetCollection) var assetCollection
  @ObservationIgnored @Shared(.userSettings) var userSettings
  @ObservationIgnored @SharedReader(.userPermissions) var userPermissions
  
  // Dependencies
  @ObservationIgnored @Dependency(\.camera) var camera
  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.uuid) var uuid
  @ObservationIgnored @Dependency(\.hapticFeedback) var hapticFeedback
  @ObservationIgnored @Dependency(\.imageGenerator) var imageGenerator
  @ObservationIgnored @Dependency(\.continuousClock) var clock

  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
    case library(LibraryModel)
    case settings(SettingsModel)
    case countdown(CountdownModel)
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
    self.isRecording
  }
  
  func recordingButtonTapped() {
    Task {
      guard !self.destination.is(\.countdown) else {
        await self.hapticFeedback.generate(.soft)
        self.destination = .none
        return
      }
      
      !isRecording ? self.prepareForRecording() : self.stopRecording()
    }
  }
  
  // @DEDA here you can determine wether or not to show the recording countdown overlay
  private func prepareForRecording() {
    Task {
      guard self.userSettings.countdownTimer == 0 else {
        await self.hapticFeedback.generate(.soft)
        self.destination = .countdown(CountdownModel())
        return
      }
      
      self.startRecording()
    }
  }
  
  private func startRecording() {
    Task {
      await self.hapticFeedback.generate(.soft)
      self.destination = .none
      try? self.camera.startRecording(self.movieFileOutput)
      self.recordingStartDate = .now
      self.isRecording = true
    }
  }

  private func stopRecording() {
    Task {
      await self.hapticFeedback.generate(.soft)
      self.destination = .none
      try? camera.stopRecording()
      self.recordingStartDate = .none
      self.isRecording = false
    }
  }

  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func navigateCameraRoll() {
    self.destination = .library(LibraryModel())
  }
  func toggleSettingsButtonTapped () {
    self.destination = self.destination.is(\.settings) ? .none : .settings(SettingsModel())
  }
  
  func dismissSettingsButtonTapped() {
    self.destination = .none
  }

  func switchCameraButtonTapped() {
    _ = Result {
      let cameraPosition: UserSettings.CameraPosition = self.userSettings.cameraPosition == .back ? .front : .back
      try self.camera.setPosition(cameraPosition.rawValue)
      self.$userSettings.cameraPosition.withLock { $0 = cameraPosition }
      self.destination = .none
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
        guard let fetchResult = try? await self.photos.fetchAssets(.lastVideo(in: assetCollection))
        else {
          print("Fetch result failed.")
          return
        }
        guard let phAsset = fetchResult.lastObject else {
          print("PHAsset was nil.")
          return
        }
        guard let avAsset = (
          await self.photos.requestAVAsset(phAsset, .none)?
            .asset as? AVURLAsset
        )
        else {
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
        try? await self.camera.connect(self.captureVideoPreviewLayer)
        // @DEDA
        // try? await self.camera.setCameraPosition(self.userSettings.cameraPosition.rawValue)
      }
      taskGroup.addTask {
        for await event in await self.camera.events() {
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
      
    case .settings:
      break
      
    case let .countdown(model):
      model.onFinish = { [weak self] in self?.startRecording() }
      break
      
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
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
        .overlay(item: $model.destination.countdown) { $model in
          CountdownView(model: model)
        }
        .overlay(content: self.overlay)
    }
  }
  
  @MainActor private var content: some View {
    Group {
      if self.model.hasFullPermissions {
        CaptureVideoPreviewLayerView(
          captureVideoPreviewLayer: self.model.captureVideoPreviewLayer
        )
        .onTapGesture(count: 2) {
          self.model.switchCameraButtonTapped()
        }
      } else {
        self.permissionsRequired
      }
    }
  }
  
  @MainActor private func toolbar() -> some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Text(self.model.navigationTitle)
        .foregroundColor(.white)
        .fontWeight(.semibold)
        .background(Color.red.opacity(self.model.isRecording ? 1 : 0))
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Settings") {
  @Shared(.userPermissions) var userPermissions = .authorized
  let model = CameraModel()
  model.destination = .settings(SettingsModel())
  return CameraView(model: model)
}

#Preview("Camera") {
  @Shared(.userPermissions) var userPermissions = .authorized
  CameraView(model: CameraModel())
}

#Preview("Permissions Required") {
  @Shared(.userPermissions) var userPermissions = .denied
  CameraView(model: CameraModel())
}
