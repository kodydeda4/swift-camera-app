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
  
  // Shared
  @ObservationIgnored @Shared(.camera) var camera
  @ObservationIgnored @Shared(.assetCollection) var assetCollection
  @ObservationIgnored @SharedReader(.userPermissions) var userPermissions

  // Dependencies
  @ObservationIgnored @Dependency(\.camera) var cameraClient
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary
  @ObservationIgnored @Dependency(\.uuid) var uuid
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  var hasFullPermissions: Bool {
    self.userPermissions == .authorized
  }
  
  var isSwitchCameraButtonDisabled: Bool {
    self.camera.isRecording
  }
  
  func recordingButtonTapped() {
    _ = Result {
      try !camera.isRecording
        ? cameraClient.startRecording(self.movieFileOutput)
        : cameraClient.stopRecording()
      
      self.$camera.isRecording.withLock { $0.toggle() }
    }
  }
  
  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func zoomButtonTapped(_ value: CGFloat) {
    _ = Result {
      try self.cameraClient.zoom(value)
      self.$camera.zoom.withLock { $0 = value }
    }
  }
  
  func switchCameraButtonTapped() {
    _ = Result {
      try self.cameraClient.switchCamera()
    }
  }
  
  func task() async {
    guard hasFullPermissions else {
      return
    }
    
    // @DEDA when you return, start the session again.
    await withTaskGroup(of: Void.self) { taskGroup in
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
      
    case .none:
      break
    }
  }
  
  func handle(_ event: CameraClient.DelegateEvent) {
    switch event {
      
    case let .avCaptureFileOutputRecordingDelegate(.fileOutput(_, outputFileURL, _, _)):
      Task {
        if let assetCollection {
          try await self.photoLibrary.performChanges(
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
  
  var body: some View {
    NavigationStack {
      if self.model.hasFullPermissions {
        self.cameraPreview
      } else {
        self.permissionsRequired
      }
    }
    .navigationBarBackButtonHidden()
    .overlay(content: self.overlay)
    .task { await self.model.task() }
    .sheet(item: $model.destination.userPermissions) { model in
      UserPermissionsSheet(model: model)
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Happy path") {
  let value: Dictionary<
    UserPermissionsClient.Feature,
    UserPermissionsClient.Status
  > = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value
  
  CameraView(model: CameraModel())
}
