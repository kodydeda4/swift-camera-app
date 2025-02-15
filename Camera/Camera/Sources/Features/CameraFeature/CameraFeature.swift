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
  var destination: Destination? { didSet { self.bind() } }
  var isRecording = false
  var recordingSecondsElapsed = 0
  var captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  
  // Shared
  @ObservationIgnored @Shared(.userSettings) var userSettings
  @ObservationIgnored @SharedReader(.photosContext) var photosContext
  @ObservationIgnored @SharedReader(.userPermissions) var userPermissions
  
  // Dependencies
  @ObservationIgnored @Dependency(\.camera) var camera
  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.audioPlayer) var audioPlayer
  @ObservationIgnored @Dependency(\.uuid) var uuid
  @ObservationIgnored @Dependency(\.textToSpeech) var textToSpeech
  @ObservationIgnored @Dependency(\.hapticFeedback) var hapticFeedback
  @ObservationIgnored @Dependency(\.continuousClock) var clock
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
    case library(LibraryModel)
    case settings(SettingsModel)
    case countdown(CountdownModel)
  }
  
  var hasFullPermissions: Bool { self.userPermissions == .authorized }
  var isCameraRollButtonPresented: Bool { !self.isRecording }
  var isSettingsButtonPresented: Bool { !self.isRecording }
  var isSwitchCameraButtonDisabled: Bool { self.isRecording }
  var isZoomButtonsPresented: Bool {
    self.userSettings.camera == .back && !self.destination.is(\.settings)
  }
  
  /// Example: `"00:00:00"`
  var navigationTitle: String {
    DateComponentsFormatter
      .recordingDuration
      .string(from: TimeInterval(recordingSecondsElapsed))
      .unsafelyUnwrapped
  }
  
  var cameraRecordingButtonState: CameraRecordingButton.State {
    if isRecording {
      return .recording
    } else if destination.is(\.countdown) {
      return .countdown
    } else {
      return .default
    }
  }
  
  func recordingButtonTapped() {
    guard !self.destination.is(\.countdown) else {
      self.hapticFeedback.generate(.soft)
      self.destination = .none
      return
    }
    
    !self.isRecording ? self.prepareForRecording() : self.stopRecording()
  }
  
  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func cameraRollButtonTapped() {
    self.hapticFeedback.generate(.soft)
    self.destination = .library(LibraryModel())
  }
  
  func settingsButtonTapped() {
    self.hapticFeedback.generate(.soft)
    self.destination = self.destination.is(\.settings) ? .none : .settings(SettingsModel())
  }
  
  func zoomButtonTapped(_ value: CGFloat) {
    _ = Result {
      try self.camera.adjust(.videoZoomFactor(value))
      self.$userSettings.zoom.withLock { $0 = value }
    }
  }
  
  func switchCameraButtonTapped() {
    _ = Result {
      let cameraPosition: UserSettings.Camera = self.userSettings.camera == .back
      ? .front
      : .back
      try self.camera.adjust(.position(cameraPosition.rawValue))
      self.$userSettings.camera.withLock { $0 = cameraPosition }
      self.destination = .none
      self.$userSettings.zoom.withLock { $0 = 1.0 }
    }
  }
  
  func torchModeToggleButtonTapped() {
    var value: UserSettings.TorchMode {
      self.userSettings.torchMode == .off ? .on : .off
    }
    _ = Result {
      try self.camera.adjust(.torchMode(value.rawValue))
      self.$userSettings.torchMode.withLock { $0 = value }
    }
  }
  
  func task() async {
    guard hasFullPermissions else {
      return
    }
    
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        for await _ in await self.clock.timer(interval: .seconds(1)) {
          await MainActor.run {
            if self.isRecording {
              self.recordingSecondsElapsed += 1
            }
          }
        }
      }
      taskGroup.addTask {
        try? await self.camera.connect(self.captureVideoPreviewLayer)
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
    self.audioPlayer.play(.beginVideoRecording)
    self.destination = .none
    try? self.camera.startRecording(.movieFileOutput(id: self.uuid()))
    self.recordingSecondsElapsed = 0
    self.isRecording = true
  }
  
  private func stopRecording() {
    self.hapticFeedback.generate(.soft)
    self.audioPlayer.play(.endVideoRecording)
    self.destination = .none
    try? camera.stopRecording()
    self.recordingSecondsElapsed = 0
    self.isRecording = false
  }
  
  private func handle(_ event: CameraClient.DelegateEvent) {
    switch event {
      
    case let .avCaptureFileOutputRecordingDelegate(.fileOutput(_, outputFileURL, _, _)):
      Task {
        guard let assetCollection = self.photosContext.assetCollection else {
          fatalError(
            "Attempting save output of video recording file to asset collection, while asset collection is nil."
          )
        }
        try await self.photos.performChanges(
          .save(contentsOf: outputFileURL, to: assetCollection)
        )
      }
    }
  }
  
  private func bind() {
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
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    return formatter
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
        .overlay {
          if self.model.hasFullPermissions {
            CameraOverlay(model: self.model)
          }
        }
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
    Group {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: self.model.torchModeToggleButtonTapped) {
          Image(systemName: self.model.userSettings.torchMode.systemImage)
            .foregroundColor(self.model.userSettings.torchMode.foregroundColor)
        }
        .buttonStyle(.plain)
      }
      ToolbarItem(placement: .principal) {
        Text(self.model.navigationTitle)
//          .foregroundColor(.white)
          .fontWeight(.semibold)
          .frame(width: 100)
          .background(Color.red.opacity(self.model.isRecording ? 1 : 0))
          .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        
      }
    }
  }
}

extension UserSettings.TorchMode {
  var systemImage: String {
    switch self {
    case .on:
      return "bolt.circle"
    case .off:
      return "bolt.slash.circle"
    case .auto:
      return "bolt.circle"
    }
  }
  var foregroundColor: Color {
    switch self {
    case .on:
      return .accentColor
    default:
      return .primary
    }
  }
}


// MARK: - SwiftUI Previews

#Preview("Camera") {
  @Shared(.userPermissions) var userPermissions = .authorized
  @Shared(.userSettings) var userSettings
  return CameraView(model: CameraModel())
}

#Preview("Permissions Required") {
  @Shared(.userPermissions) var userPermissions = .denied
  CameraView(model: CameraModel())
}

#Preview("Settings") {
  @Shared(.userPermissions) var userPermissions = .authorized
  let model = CameraModel()
  model.destination = .settings(SettingsModel())
  return CameraView(model: model)
}
