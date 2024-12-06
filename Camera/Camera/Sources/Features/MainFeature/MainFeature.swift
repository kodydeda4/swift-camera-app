import ARKit
import AsyncAlgorithms
import AVFoundation
import Dependencies
import Photos
import PhotosUI
import RealityKit
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class MainModel {
  var isRecording = false
  var recordingDurationSeconds = 0
  var destination: Destination? { didSet { self.bind() } }
  var recorder: ARVideoRecorder?
  
  @ObservationIgnored
  @Shared(.userPermissions) var userPermissionsValues
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissions
  
  @CasePathable
  enum Destination {
    case arObjectPicker(ARObjectPickerModel)
    case userPermissions(UserPermissionsModel)
  }
  
  var hasFullPermissions: Bool {
    self.userPermissionsValues[.camera] == .authorized &&
      self.userPermissionsValues[.microphone] == .authorized &&
      self.userPermissionsValues[.photos] == .authorized
  }
  
  var isDeleteButtonDisabled: Bool {
    false
  }
  
  func recordingButtonTapped() {
    !self.isRecording
      ? self.recorder?.startRecording()
      : self.recorder?.stopRecording { url in self.saveVideoToPhotos(url: url) }
    self.isRecording.toggle()
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
    // self.startCaptureSession(with: .default(for: .video))
    
    Task.detached {
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask {
//          for await event in await self.recordingDelegate.events {
//            await self.handleRecordingDelegateEvent(event)
//          }
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
  
  internal func saveVideoToPhotos(url: URL) {
    PHPhotoLibrary.requestAuthorization { status in
      if status == .authorized {
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, error in
          if success {
            print("Video saved to Photos!")
          } else {
            print("Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI

// hi

struct MainView: View {
  @Bindable public var model: MainModel
  
  var body: some View {
    NavigationStack {
      Group {
        if self.model.hasFullPermissions {
          ARViewContainer(model: self.model)
            .edgesIgnoringSafeArea(.all)
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
