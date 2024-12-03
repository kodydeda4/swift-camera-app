import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import PhotosUI
import SwiftUI
import Photos

@MainActor
@Observable
final class MainModel {
  var isRecording = false
  var recordingDurationSeconds = 0
  let avCaptureSession = AVCaptureSession()
  var avCaptureDevice: AVCaptureDevice?
  var avCaptureDeviceInput: AVCaptureDeviceInput?
  var avCaptureMovieFileOutput = AVCaptureMovieFileOutput()
  let avVideoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
  let avVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  var recordingDelegate = MovieCaptureDelegate()
  var isVideoPermissionGranted: Bool { avVideoAuthorizationStatus == .authorized }
  var destination: Destination? { didSet { self.bind() } }
  var userPermissions: any UserPermissionsServiceProtocol
  
  @CasePathable
  enum Destination {
    case arObjectPicker(ARObjectPickerModel)
    case userPermissions(UserPermissionsModel)
  }
  
  init(userPermissions: any UserPermissionsServiceProtocol = UserPermissionsService()) {
    self.userPermissions = userPermissions
  }
  
  var hasUserPermissions: Bool {
    self.userPermissions.camera &&
    self.userPermissions.microphone &&
    self.userPermissions.photos
  }

  var isDeleteButtonDisabled: Bool {
    false
  }
  
  func recordingButtonTapped() {
    !isRecording ? startRecording() : stopRecording()
  }
  
  func settingsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func newObjectButtonTapped() {
    self.destination = .arObjectPicker(ARObjectPickerModel())
  }
  
  func deleteButtonTapped() {
    //...
  }

  func task() async {
    self.startCaptureSession(with: .default(for: .video))
    
    Task.detached {
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask {
          for await event in await self.recordingDelegate.events {
            await self.handleRecordingDelegateEvent(event)
          }
        }
      }
    }
  }
  
  private func bind() {
    switch destination {
      
    case let .userPermissions(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case let .arObjectPicker(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case .none:
      break
    }
  }
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable public var model: MainModel
  
  var body: some View {
    NavigationStack {
      Group {
        if self.model.hasUserPermissions {
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
    .sheet(item: $model.destination.arObjectPicker) { model in
      ARObjectPickerSheet(model: model)
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
