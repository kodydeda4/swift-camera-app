import SwiftUI
import AVFoundation
import Photos
import XCTestDynamicOverlay

@Observable
@MainActor
final class UserPermissionsModel: Identifiable {
  let id = UUID()
  var camera: Bool { userPermissions.camera }
  var microphone: Bool { userPermissions.microphone }
  var photos: Bool { userPermissions.photos }
  var application: any ApplicationServiceProtocol
  var userPermissions: any UserPermissionsServiceProtocol
  var dismiss: () -> Void = unimplemented("UserPermissionsModel.dismiss")
  var onContinueButtonTapped: () -> Void = unimplemented("UserPermissionsModel.onContinueButtonTapped")

  init(
    application: any ApplicationServiceProtocol = ApplicationService(),
    userPermissions: any UserPermissionsServiceProtocol = UserPermissionsService()
  ) {
    self.application = application
    self.userPermissions = userPermissions
  }
  
  var isContinueButtonDisabled: Bool {
    !(camera && microphone && photos)
  }
  
  func cameraPermissionsButtonTapped() {
    guard !camera else {
      return
    }
    guard self.userPermissions.statusCamera == .notDetermined else {
      try? self.application.openSettings()
      return
    }
    Task {
      await self.userPermissions.requestCamera()
    }
  }
  
  func microphonePermissionsButtonTapped() {
    guard !microphone else {
      return
    }
    guard self.userPermissions.statusMicrophone == .undetermined else {
      try? self.application.openSettings()
      return
    }
    Task {
      await self.userPermissions.requestMicrophone()
    }
  }
  
  func photoLibraryPermissionsButtonTapped() {
    guard !photos else {
      return
    }
    guard self.userPermissions.statusPhotos == .notDetermined else {
      try? self.application.openSettings()
      return
    }
    Task {
      await self.userPermissions.requestPhotos()
    }
  }
  
  func cancelButtonTapped() {
    self.dismiss()
  }
  
  func continueButtonTapped() {
    self.onContinueButtonTapped()
  }
}

// MARK: - SwiftUI

struct UserPermissionsView: View {
  @Bindable var model: UserPermissionsModel
  
  var body: some View {
    VStack {
      Text("This app requires permissions")
        .font(.title)
        .fontWeight(.bold)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top)
      
      self.permissionsContent
      
      Spacer()
      
      Button(action: self.model.continueButtonTapped) {
        Text("Continue")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(self.model.isContinueButtonDisabled)
      .padding()
    }
    .padding(.horizontal, 32)
    .frame(maxWidth: .infinity, alignment: .leading)
    .navigationTitle("User Permissions")
    .navigationBarTitleDisplayMode(.inline)
  }
  
  private var permissionsContent: some View {
    VStack {
      Button(action: self.model.cameraPermissionsButtonTapped) {
        self.permissionsView(
          title: "Camera",
          subtitle: "Record AR Videos",
          systemImage: "camera.fill",
          style: self.model.camera ? .green : Color(.systemGray6)
        )
      }
      Button(action: self.model.microphonePermissionsButtonTapped) {
        self.permissionsView(
          title: "Microphone",
          subtitle: "Add sound to your AR videos",
          systemImage: "microphone.fill",
          style: self.model.microphone ? .green : Color(.systemGray6)
        )
      }
      Button(action: self.model.photoLibraryPermissionsButtonTapped) {
        self.permissionsView(
          title: "Photo Library",
          subtitle: "Save your AR videos",
          systemImage: "photo.stack",
          style: self.model.photos ? .green : Color(.systemGray6)
        )
      }
    }
    .buttonStyle(.plain)
  }
  
  private func permissionsView(
    title: String,
    subtitle: String,
    systemImage: String,
    style: Color
  ) -> some View {
    HStack(spacing: 16) {
      Image(systemName: systemImage)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .padding()
        .background(style)
        .clipShape(Circle())
      
      VStack(alignment: .leading) {
        Text(title)
          .font(.headline)
        Text(subtitle)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    UserPermissionsView(model: UserPermissionsModel())
  }
}
