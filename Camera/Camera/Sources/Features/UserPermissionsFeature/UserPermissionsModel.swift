import SwiftUI
import AVFoundation
import Photos

@Observable
@MainActor
final class UserPermissionsModel: Identifiable {
  let id = UUID()
  var camera = false
  var microphone = false
  var photos = false
  var delegate: Delegate
  
  struct Delegate {
    var dismiss: () -> Void = {}
    var continueButtonTapped: () -> Void = {}
  }
  
  //@DEDA .bind() in pointfree apps?..
  init(delegate: Delegate = .init()) {
    self.delegate = delegate
  }
  
  var isContinueButtonDisabled: Bool {
    !(camera && microphone && photos)
  }
  
  func task() async {
    self.camera = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    self.microphone = AVAudioApplication.shared.recordPermission == .granted
    self.photos = PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized
  }
  
  func requestCameraPermissionsButtonTapped() {
    Task {
      self.camera = await AVCaptureDevice.requestAccess(for: .video)
    }
  }
  
  func requestMicrophonePermissionsButtonTapped() {
    Task {
      self.microphone = await AVAudioApplication.requestRecordPermission()
    }
  }
  
  func requestPhotoLibraryPermissionsButtonTapped() {
    Task {
      self.photos = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
    }
  }
  
  func openSettingsButtonTapped() {
    UIApplication.shared.open(
      URL(string: UIApplication.openSettingsURLString).unsafelyUnwrapped,
      options: [:],
      completionHandler: nil
    )
  }
  
  func cancelButtonTapped() {
    self.delegate.dismiss()
  }

  func continueButtonTapped() {
    self.delegate.continueButtonTapped()
  }
}

// MARK: - SwiftUI

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
      
      Button {
        self.model.openSettingsButtonTapped()
      } label: {
        Text("Open Settings")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.top, 32)

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
    .task { await self.model.task() }
  }
  
  private var permissionsContent: some View {
    VStack {
      Button(action: self.model.requestCameraPermissionsButtonTapped) {
        self.permissionsView(
          title: "Camera",
          subtitle: "Record AR Videos",
          systemImage: "camera.fill",
          style: self.model.camera ? .green : Color(.systemGray6)
        )
      }
      Button(action: self.model.requestMicrophonePermissionsButtonTapped) {
        self.permissionsView(
          title: "Microphone",
          subtitle: "Add sound to your AR videos",
          systemImage: "microphone.fill",
          style: self.model.microphone ? .green : Color(.systemGray6)
        )
      }
      Button(action: self.model.requestPhotoLibraryPermissionsButtonTapped) {
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
