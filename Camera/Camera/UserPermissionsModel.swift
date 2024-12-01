import SwiftUI
import AVFoundation

@Observable
@MainActor
final class UserPermissionsModel {
  var cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
  var microphonePermission = AVAudioApplication.shared.recordPermission
  
  var isContinueButtonDisabled: Bool {
    self.cameraPermission != .authorized ||
    self.microphonePermission != .granted
  }
  
  func requestCameraPermissionsButtonTapped() {
    print("requestCameraPermissionsButtonTapped")
    
    Task {
      _ = await AVCaptureDevice.requestAccess(for: .video)
    }
  }
  
  func requestMicrophonePermissionsButtonTapped() {
    print("requestMicrophonePermissionsButtonTapped")
    
    Task {
      _ = await AVAudioApplication.requestRecordPermission()
    }
  }
  
  func requestPhotoLibraryPermissionsButtonTapped() {
    print("requestPhotoLibraryPermissionsButtonTapped")
    //...
  }
  
  func continueButtonTapped() {
    //...
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
      
      VStack {
        Button(action: self.model.requestCameraPermissionsButtonTapped) {
          self.permissionsView(
            title: "Camera",
            subtitle: "Record AR Videos",
            systemImage: "camera.fill",
            style: self.model.cameraPermission == .authorized ? .green : Color(.systemGray6)
          )
        }
        Button(action: self.model.requestMicrophonePermissionsButtonTapped) {
          self.permissionsView(
            title: "Microphone",
            subtitle: "Add sound to your AR videos",
            systemImage: "microphone.fill",
            style: self.model.microphonePermission == .granted ? .green : Color(.systemGray6)
          )
        }
        Button(action: self.model.requestPhotoLibraryPermissionsButtonTapped) {
          self.permissionsView(
            title: "Photo Library",
            subtitle: "Save your AR videos",
            systemImage: "photo.stack",
            style: Color(.systemGray6)
          )
        }
      }
      .buttonStyle(.plain)
      
      Spacer()
      
      Button {
        self.model.continueButtonTapped()
      } label: {
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
