import SwiftUI
import SwiftUINavigation
import AVFoundation
import UIKit
import AVFoundation
import AsyncAlgorithms
import AVFoundation
import Photos

@Observable
final class MainModel: Identifiable {
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
  var destination: Destination?
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
    case arObjectPicker(ARObjectPickerModel)
  }

  var isDeleteButtonDisabled: Bool {
    false
  }
  
  @MainActor
  func recordingButtonTapped() {
//    !isRecording ? startRecording() : stopRecording()
  }
  
  @MainActor
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
  
  @MainActor
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
  
  func task() async {}
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable var model: MainModel
  
  var body: some View {
    NavigationStack {
      VStack {
        AVCaptureVideoPreviewLayerView(
          avVideoPreviewLayer: self.model.avVideoPreviewLayer
        )
      }
      .task { await self.model.task() }
//      .overlay(content: self.overlay)
      .sheet(item: $model.destination.userPermissions) { model in
        UserPermissionsSheet(model: model)
      }
      .sheet(item: $model.destination.arObjectPicker) { model in
        ARObjectPickerSheet(model: model)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
