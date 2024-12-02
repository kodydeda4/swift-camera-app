import SwiftUI
import AVFoundation
import Photos

@Observable
@MainActor
final class UserPermissionsModel: Identifiable {
  let id: UUID
  let options: Options
  private let delegate: Delegate
  private let application: any ApplicationServiceProtocol
  private let userPermissions: UserPermissionsService

  struct Delegate {
    var dismiss: () -> Void = {}
    var continueButtonTapped: () -> Void = {}
  }
  
  struct Options {
    var isContinueButtonHidden = false
  }
  
  init(
    id: UUID = UUID(),
    delegate: Delegate = Delegate(),
    options: Options = Options(),
    application: any ApplicationServiceProtocol = ApplicationService(),
    userPermissions: UserPermissionsService = UserPermissionsService()
  ) {
    self.id = id
    self.delegate = delegate
    self.options = options
    self.application = application
    self.userPermissions = userPermissions
  }
  
  var isContinueButtonDisabled: Bool {
    !(isAuthorized(.camera) && isAuthorized(.microphone) && isAuthorized(.photoLibrary))
  }
  
  func isAuthorized(_ privacyFeature: UserPermissionsService.PrivacyFeature) -> Bool {
    self.userPermissions.isAuthorized(privacyFeature)
  }

  func privacyFeatureButtonTapped(_ privacyFeature: UserPermissionsService.PrivacyFeature) {
    guard !userPermissions.isAuthorized(privacyFeature) else {
      return
    }
    guard userPermissions.isStatusDetermined(privacyFeature) else {
      try? self.application.openSettings()
      return
    }
    Task {
      await self.userPermissions.request(privacyFeature)
    }
  }
  
  func cancelButtonTapped() {
    self.delegate.dismiss()
  }
  
  func continueButtonTapped() {
    self.delegate.continueButtonTapped()
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
      
      if !self.model.options.isContinueButtonHidden {
        Button(action: self.model.continueButtonTapped) {
          Text("Continue")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(self.model.isContinueButtonDisabled)
        .padding()
      }
    }
    .padding(.horizontal, 32)
    .frame(maxWidth: .infinity, alignment: .leading)
    .navigationTitle("User Permissions")
    .navigationBarTitleDisplayMode(.inline)
  }
  
  private var permissionsContent: some View {
    VStack {
      Button {
        self.model.privacyFeatureButtonTapped(.camera)
      } label: {
        self.permissionsView(
          title: "Camera",
          subtitle: "Record AR Videos",
          systemImage: "camera.fill",
          isAuthorized: self.model.isAuthorized(.camera)
        )
      }
      Button {
        self.model.privacyFeatureButtonTapped(.microphone)
      } label: {
        self.permissionsView(
          title: "Microphone",
          subtitle: "Add sound to your AR videos",
          systemImage: "microphone.fill",
          isAuthorized: self.model.isAuthorized(.microphone)
        )
      }
      Button {
        self.model.privacyFeatureButtonTapped(.photoLibrary)
      } label: {
        self.permissionsView(
          title: "Photo Library",
          subtitle: "Save your AR videos",
          systemImage: "photo.stack",
          isAuthorized: self.model.isAuthorized(.photoLibrary)
        )
      }
    }
    .buttonStyle(.plain)
  }
  
  private func permissionsView(
    title: String,
    subtitle: String,
    systemImage: String,
    isAuthorized: Bool
  ) -> some View {
    HStack(spacing: 16) {
      Image(systemName: systemImage)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .padding()
        .background(isAuthorized ? .green : Color(.systemGray6))
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

struct UserPermissionsSheet: View {
  @Bindable var model: UserPermissionsModel
  
  var body: some View {
    NavigationStack {
      UserPermissionsView(model: self.model).toolbar {
        Button("Cancel") {
          self.model.cancelButtonTapped()
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    UserPermissionsView(model: UserPermissionsModel())
  }
}
