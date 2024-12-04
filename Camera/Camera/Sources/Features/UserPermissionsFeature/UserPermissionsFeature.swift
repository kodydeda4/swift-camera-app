import AVFoundation
import Dependencies
import IssueReporting
import Photos
import Sharing
import SwiftUI

@Observable
@MainActor
final class UserPermissionsModel: Identifiable {
  let id = UUID()
  var dismiss: () -> Void = unimplemented("UserPermissionsModel.dismiss")
  var onContinueButtonTapped: ()
    -> Void = unimplemented("UserPermissionsModel.onContinueButtonTapped")
  
  @ObservationIgnored
  @Shared(.userPermissions) var userPermissionsValues
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissions
  
  @ObservationIgnored
  @Dependency(\.application) var application
  
  var isContinueButtonDisabled: Bool {
    let hasFullPermissions =
      self.userPermissionsValues[.camera] == .authorized &&
      self.userPermissionsValues[.microphone] == .authorized &&
      self.userPermissionsValues[.photos] == .authorized
    
    return !hasFullPermissions
  }
  
  func cancelButtonTapped() {
    self.dismiss()
  }
  
  func continueButtonTapped() {
    self.onContinueButtonTapped()
  }
  
  func request(_ feature: UserPermissionsClient.Feature) {
    switch userPermissionsValues[feature] {
      
    case .authorized:
      break
      
    case .denied:
      try? self.application.openSettings()
      
    case .none,
         .undetermined:
      Task {
        let newValue = await self.userPermissions.request(feature)
        self.$userPermissionsValues.withLock {
          $0[feature] = newValue ? .authorized : .denied
        }
      }
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
      Button(action: { self.model.request(.camera) }) {
        self.permissionsView(
          title: "Camera",
          subtitle: "Record AR Videos",
          systemImage: "camera.fill",
          style: self.model.userPermissionsValues[.camera] == .authorized
            ? .green
            : Color(.systemGray6)
        )
      }
      Button(action: { self.model.request(.microphone) }) {
        self.permissionsView(
          title: "Microphone",
          subtitle: "Add sound to your AR videos",
          systemImage: "microphone.fill",
          style: self.model.userPermissionsValues[.microphone] == .authorized
            ? .green
            : Color(.systemGray6)
        )
      }
      Button(action: { self.model.request(.photos) }) {
        self.permissionsView(
          title: "Photo Library",
          subtitle: "Save your AR videos",
          systemImage: "photo.stack",
          style: self.model.userPermissionsValues[.photos] == .authorized
            ? .green
            : Color(.systemGray6)
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
