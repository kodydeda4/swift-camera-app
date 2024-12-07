import Dependencies
import Photos
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
  @Shared(.userPermissions) var userPermissions
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissionsClient
  
  @ObservationIgnored
  @Dependency(\.photoLibrary) var photoLibrary

  @CasePathable
  enum Destination {
    case arObjectPicker(ARObjectPickerModel)
    case userPermissions(UserPermissionsModel)
  }
  
  var hasFullPermissions: Bool {
    self.userPermissions[.camera] == .authorized &&
    self.userPermissions[.microphone] == .authorized &&
    self.userPermissions[.photos] == .authorized
  }
  
  var isDeleteButtonDisabled: Bool {
    false
  }
  
  func recordingButtonTapped() {
    !self.isRecording ? self.startRecording() : self.stopRecording()
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
  
  private func startRecording() {
    self.recorder?.startRecording()
  }
  
  private func stopRecording() {
    self.recorder?.stopRecording { url in
      self.photoLibrary().performChanges({
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      })
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
          ARViewContainer(model: self.model)
            .edgesIgnoringSafeArea(.all)
        } else {
          self.permissionsRequired
        }
      }
    }
    .navigationBarBackButtonHidden()
    .overlay(content: self.overlay)
    .sheet(item: $model.destination.userPermissions) { model in
      UserPermissionsSheet(model: model)
    }
    .sheet(item: $model.destination.arObjectPicker) { model in
      ARObjectPickerSheet(model: model)
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
