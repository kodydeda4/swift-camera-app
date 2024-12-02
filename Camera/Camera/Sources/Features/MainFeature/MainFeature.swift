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
  var destination: Destination?
  var userPermissions: UserPermissionsService
  var isSwiftUIPreview: Bool//@DEDA plz
  
  init(
    isSwiftUIPreview: Bool = false,
    userPermissions: UserPermissionsService = UserPermissionsService()
  ) {
    self.isSwiftUIPreview = isSwiftUIPreview
    self.userPermissions = userPermissions
  }
  
  var hasUserPermissions: Bool {
    self.userPermissions.isAuthorized([.camera, .microphone, .photoLibrary])
  }
  
  @CasePathable
  enum Destination {
    case arObjectPicker(ARObjectPickerModel)
    case userPermissions(UserPermissionsModel)
  }

  var isDeleteButtonDisabled: Bool {
    false
  }
  
  func recordingButtonTapped() {
    !isRecording ? startRecording() : stopRecording()
  }
  
  func settingsButtonTapped() {
    self.destination = .userPermissions(
      UserPermissionsModel(delegate: .init(
        dismiss: { [weak self] in
          self?.destination = .none
        },
        continueButtonTapped: {}
      ))
    )
  }
  
  func newObjectButtonTapped() {
    self.destination = .arObjectPicker(ARObjectPickerModel(
      delegate: .init(dismiss: { [weak self] in
        self?.destination = .none
      })
    ))
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
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable public var model: MainModel
  
  var body: some View {
    NavigationStack {
      if self.model.hasUserPermissions {
        self.camera
      } else {
        self.notEnoughPermissions
      }
    }
    .navigationBarBackButtonHidden()
    .tabViewStyle(.page(indexDisplayMode: .never))
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

extension MainModel {
  static var previewValue = MainModel.init(isSwiftUIPreview: true)
}

#Preview {
  MainView(model: .previewValue)
}
