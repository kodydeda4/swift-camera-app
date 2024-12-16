import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation
import AVFoundation

@MainActor
@Observable
final class MainModel {
  internal var isRecording = false
  internal var recordingDurationSeconds = 0
  internal let avCaptureSession = AVCaptureSession()
  internal var avCaptureDevice: AVCaptureDevice?
  internal var avCaptureDeviceInput: AVCaptureDeviceInput?
  internal var avCaptureMovieFileOutput = AVCaptureMovieFileOutput()
  internal let avVideoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
  internal let avVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  internal var recordingDelegate = MovieCaptureDelegate()
  internal var isVideoPermissionGranted: Bool { avVideoAuthorizationStatus == .authorized }
  
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored
  @Shared(.userPermissions) var userPermissions
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissionsClient
  
  @ObservationIgnored
  @Dependency(\.photoLibrary) var photoLibrary
  
  @ObservationIgnored
  @Dependency(\.uuid) var uuid
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  var hasFullPermissions: Bool {
    self.userPermissions[.camera] == .authorized &&
    self.userPermissions[.microphone] == .authorized &&
    self.userPermissions[.photos] == .authorized
  }
  
  func recordingButtonTapped() {
    !self.isRecording ? self._startRecording() : self._stopRecording()
    self.isRecording.toggle()
  }
  
  func settingsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  private func bind() {
    switch destination {
      
    case let .userPermissions(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case .none:
      break
    }
  }
  
  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        for await event in await self.recordingDelegate.events {
          await self._handleRecordingDelegateEvent(event)
        }
      }
    }
  }
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable public var model: MainModel
  
  var body: some View {
    NavigationStack {
      Group {
        if self.model.hasFullPermissions {
          self.camera
        } else {
          self.permissionsRequired
        }
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
