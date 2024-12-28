import AVFoundation
import CasePaths
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
  var isRecording = false
  var recordingStartDate: Date?
  var captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()

  // Shared
  @ObservationIgnored @Shared(.videos) var videos
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
  
  var hasFullPermissions: Bool {
    self.userPermissions == .authorized
  }
  
  var isSwitchCameraButtonDisabled: Bool {
    self.isRecording
  }
  
  func recordingButtonTapped() {
    guard !self.destination.is(\.countdown) else {
      self.hapticFeedback.generate(.soft)
      self.destination = .none
      return
    }
    
    !isRecording ? self.prepareForRecording() : self.stopRecording()
  }
  
  // @DEDA here you can determine wether or not to show the recording countdown overlay
  private func prepareForRecording() {
    guard self.userSettings.countdownTimer == 0 else {
      self.hapticFeedback.generate(.soft)
      self.destination = .countdown(CountdownModel())
      return
    }
    
    self.startRecording()
  }
  
  private func startRecording() {
    self.hapticFeedback.generate(.soft)
    self.destination = .none
    try? self.camera.startRecording(.movieFileOutput(id: self.uuid()))
    self.recordingStartDate = .now
    self.isRecording = true
  }

  private func stopRecording() {
    self.hapticFeedback.generate(.soft)
    self.destination = .none
    try? camera.stopRecording()
    self.recordingStartDate = .none
    self.isRecording = false
  }

  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func navigateCameraRoll() {
    self.destination = .library(LibraryModel())
  }
  
  func toggleSettingsButtonTapped () {
    self.hapticFeedback.generate(.soft)
    self.destination = self.destination.is(\.settings) ? .none : .settings(SettingsModel())
  }
  
  func dismissSettingsButtonTapped() {
    self.destination = .none
  }

  func switchCameraButtonTapped() {
    _ = Result {
      let cameraPosition: UserSettings.Camera = self.userSettings.camera == .back
        ? .front
        : .back
      try self.camera.setPosition(cameraPosition.rawValue)
      self.$userSettings.camera.withLock { $0 = cameraPosition }
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
            self.navigationTitle = DateComponentsFormatter.recordingDuration.string(
              from: Date().timeIntervalSince(self.recordingStartDate ?? .now)
            ) ?? "00:00:00"
          }
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

fileprivate extension URL {
  static func movieFileOutput(id: UUID) -> Self {
    URL.temporaryDirectory
      .appending(component: id.uuidString)
      .appendingPathExtension(for: .quickTimeMovie)
  }
}

fileprivate extension DateComponentsFormatter {
  static var recordingDuration: DateComponentsFormatter {
    let rv = DateComponentsFormatter()
    rv.allowedUnits = [.hour, .minute, .second] // Use hours, minutes, and seconds
    rv.unitsStyle = .positional // Ensures the "00:00:00" style
    rv.zeroFormattingBehavior = .pad // Pads with leading zeros
    return rv
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
        .overlay(isPresented: .constant(self.model.userSettings.isGridEnabled)) {
          CameraGridView()
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

// @DEDA fix up the grid bro
private struct CameraGridView: View {
  private let color = Color.gray
  private let spacing: CGFloat = 128
  private let items = Array(1...4)
  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]
  
  var body: some View {
    ZStack {
      VStack(spacing: spacing * 2) {
        Rectangle()
          .frame(height: 1)
          .foregroundColor(color)
        
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color(.systemGray6))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      
      HStack(spacing: spacing) {
        Rectangle()
          .frame(width: 1)
          .foregroundColor(color)
        
        Rectangle()
          .frame(width: 1)
          .foregroundColor(color)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .opacity(0.5)
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
  @Shared(.userSettings) var userSettings
  $userSettings.isGridEnabled.withLock { $0 = true }
  return CameraView(model: CameraModel())
}

#Preview("Permissions Required") {
  @Shared(.userPermissions) var userPermissions = .denied
  CameraView(model: CameraModel())
}
