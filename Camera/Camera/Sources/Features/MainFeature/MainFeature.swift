import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class MainModel {
  var buildNumber: Build.Version { Build.version }
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored @Shared(.userPermissions) private var userPermissions
  @ObservationIgnored @Shared(.camera) var camera
  @ObservationIgnored @Dependency(\.camera) private var cameraClient
  @ObservationIgnored @Dependency(\.photoLibrary) private var photoLibrary
  @ObservationIgnored @Dependency(\.uuid) private var uuid
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  var hasFullPermissions: Bool {
    self.userPermissions[.camera] == .authorized &&
    self.userPermissions[.microphone] == .authorized &&
    self.userPermissions[.photos] == .authorized
  }
  
  var isSwitchCameraButtonDisabled: Bool {
    self.camera.isRecording
  }
  
  func recordingButtonTapped() {
    !self.camera.isRecording
    ? cameraClient.startRecording(self.movieFileOutput)
    : cameraClient.stopRecording()
  }
  
  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func zoomButtonTapped(_ value: CGFloat) {
    self.cameraClient.zoom(value)
  }
  
  func switchCameraButtonTapped() {
    self.cameraClient.switchCamera()
  }
  
  func captureLibraryButtonTapped() {
    //...
  }
  
  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        for await event in await self.cameraClient.events() {
          await self.handle(event)
        }
      }
    }
  }
}

// MARK: Private

private extension MainModel {
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
      
    case let .fileOutput(_, outputFileURL, _, _):
      Task.detached {
        try await self.photoLibrary().performChanges({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        })
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

struct MainView: View {
  @Bindable var model: MainModel
  
  var body: some View {
    NavigationStack {
      if self.model.hasFullPermissions {
        self.camera
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
  
  MainView(model: MainModel())
}
