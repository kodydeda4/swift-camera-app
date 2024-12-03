import SwiftUI
import AVFoundation
import Photos
import Sharing
import Dependencies
import IssueReporting

@Observable
@MainActor
final class UserPermissionsModel: Identifiable {
  let id = UUID()
  var dismiss: () -> Void = unimplemented("UserPermissionsModel.dismiss")
  var onContinueButtonTapped: () -> Void = unimplemented("UserPermissionsModel.onContinueButtonTapped")
  
  @ObservationIgnored
  @Shared(.userPermissions) var userPermissionsValues
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissions
  
  @ObservationIgnored
  @Dependency(\.application) var application

  var isContinueButtonDisabled: Bool {
    !(userPermissionsValues.camera && userPermissionsValues.microphone && userPermissionsValues.photos)
  }
  
  func cancelButtonTapped() {
    self.dismiss()
  }
  
  func continueButtonTapped() {
    self.onContinueButtonTapped()
  }
  
  func cameraPermissionsButtonTapped() {
    guard !userPermissionsValues.camera else {
      return
    }
    guard self.userPermissions.status(.camera) == .undetermined else {
      try? self.application.openSettings()
      return
    }
    Task {
      let newValue = await self.userPermissions.request(.camera)
      self.$userPermissionsValues.camera.withLock { $0 = newValue }
    }
  }
  
  func microphonePermissionsButtonTapped() {
    guard !userPermissionsValues.microphone else {
      return
    }
    guard self.userPermissions.status(.microphone) == .undetermined else {
      try? self.application.openSettings()
      return
    }
    Task {
      let newValue = await self.userPermissions.request(.microphone)
      self.$userPermissionsValues.microphone.withLock { $0 = newValue }
    }
  }
  
  func photoLibraryPermissionsButtonTapped() {
    guard !userPermissionsValues.photos else {
      return
    }
    guard self.userPermissions.status(.photos) == .undetermined else {
      try? self.application.openSettings()
      return
    }
    Task {
      let newValue = await self.userPermissions.request(.photos)
      self.$userPermissionsValues.photos.withLock { $0 = newValue }
    }
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
          style: self.model.userPermissionsValues.camera ? .green : Color(.systemGray6)
        )
      }
      Button(action: self.model.microphonePermissionsButtonTapped) {
        self.permissionsView(
          title: "Microphone",
          subtitle: "Add sound to your AR videos",
          systemImage: "microphone.fill",
          style: self.model.userPermissionsValues.microphone ? .green : Color(.systemGray6)
        )
      }
      Button(action: self.model.photoLibraryPermissionsButtonTapped) {
        self.permissionsView(
          title: "Photo Library",
          subtitle: "Save your AR videos",
          systemImage: "photo.stack",
          style: self.model.userPermissionsValues.photos ? .green : Color(.systemGray6)
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
