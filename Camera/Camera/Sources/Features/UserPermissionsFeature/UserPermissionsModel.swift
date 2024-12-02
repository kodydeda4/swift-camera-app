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
  
  static var cameraStatus: AVAuthorizationStatus {
    AVCaptureDevice.authorizationStatus(for: .video)
  }
  static var microphoneStatus: AVAudioApplication.recordPermission {
    AVAudioApplication.shared.recordPermission
  }
  static var photosStatus: PHAuthorizationStatus {
    PHPhotoLibrary.authorizationStatus(for: .addOnly)
  }
  
  //@DEDA .bind() in pointfree apps?..
  init(delegate: Delegate = Delegate()) {
    self.delegate = delegate
  }
  
  var isContinueButtonDisabled: Bool {
    !(camera && microphone && photos)
  }
  
  func task() async {
    self.camera = Self.cameraStatus == .authorized
    self.microphone = Self.microphoneStatus == .granted
    self.photos = Self.photosStatus == .authorized
  }

  func cameraPermissionsButtonTapped() {
    guard !camera else {
      return
    }
    guard Self.cameraStatus == .notDetermined else {
      try? self.openSettings()
      return
    }
    Task {
      self.camera = await AVCaptureDevice.requestAccess(for: .video)
    }
  }
  
  func microphonePermissionsButtonTapped() {
    guard !microphone else {
      return
    }
    guard Self.microphoneStatus == .undetermined else {
      try? self.openSettings()
      return
    }
    Task {
      self.microphone = await AVAudioApplication.requestRecordPermission()
    }
  }
  
  func photoLibraryPermissionsButtonTapped() {
    guard !photos else {
      return
    }
    guard Self.photosStatus == .notDetermined else {
      try? self.openSettings()
      return
    }
    Task {
      self.photos = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
    }
  }
  
  private func openSettings() throws {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      throw AnyError("GG")
    }
    guard UIApplication.shared.canOpenURL(url) else {
      throw AnyError("GG")
    }
    UIApplication.shared.open(
      url,
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
    .task { await self.model.task() }
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
