import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

// @DEDA looks like if you come back to the app after backgrounding, video recording no longer works.

@MainActor
@Observable
final class MainModel {
  private(set) var captureSession = AVCaptureSession()
  private(set) var captureDevice: AVCaptureDevice?
  private(set) var captureDeviceInput: AVCaptureDeviceInput?
  private(set) var captureMovieFileOutput = AVCaptureMovieFileOutput()
  private(set) var captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  private(set) var captureFileOutputRecordingDelegate = CaptureFileOutputRecordingDelegate()
  private(set) var isRecording = false
  
  var buildNumber: Build.Version { Build.version }
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored
  @Shared(.userPermissions) private var userPermissions
  
  @ObservationIgnored
  @Dependency(\.userPermissions) private var userPermissionsClient
  
  @ObservationIgnored
  @Dependency(\.photoLibrary) private var photoLibrary
  
  @ObservationIgnored
  @Dependency(\.uuid) private var uuid
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  var hasFullPermissions: Bool {
    self.userPermissions[.camera] == .authorized &&
    self.userPermissions[.microphone] == .authorized &&
    self.userPermissions[.photos] == .authorized
  }
  
  var isSwitchCameraButtonDisabled: Bool {
    self.isRecording
  }
  
  func recordingButtonTapped() {
    let result = Result { try !isRecording ? startRecording() : stopRecording() }
    print("\(Self.self).recordingButtonTapped.\(result)")
  }
  
  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func switchCameraButtonTapped() {
    let result = Result { try self.switchCamera() }
    print("\(Self.self).switchCamera", result)
  }
  
  func captureLibraryButtonTapped() {
    //...
  }
  
  func bind() {
    switch destination {
      
    case let .userPermissions(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case .none:
      break
    }
  }
  
  func task() async {
    await withTaskCancellationHandler {
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask {
          let result = await Result { try await self.configureSession() }
          print(result)
        }
        taskGroup.addTask {
          for await event in await self.captureFileOutputRecordingDelegate.events {
            await self.handle(event)
          }
        }
      }
    } onCancel: { [captureSession = self.captureSession] in
      print("Session cancelled.")
      captureSession.stopRunning()
    }
  }
  
  // MARK: - Private
  
  private func configureSession() throws {
    self.captureSession.beginConfiguration()
    
    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    let output = self.captureMovieFileOutput
    
    guard let device else {
      throw AnyError("\(String(describing: device)) returned nil.")
    }
    guard let input = try? AVCaptureDeviceInput(device: device) else {
      throw AnyError("Could not create input for \(device)")
    }
    guard self.captureSession.canAddInput(input) else {
      throw AnyError("self.avCaptureSession.canAddInput(input) returned false.")
    }
    guard self.captureSession.canAddOutput(output) else {
      throw AnyError("self.avCaptureSession.canAddOutput(output) returned false.")
    }
    
    self.captureDevice = device
    self.captureDeviceInput = input
    self.captureSession.addInput(input)
    self.captureSession.addOutput(output)
    self.captureSession.commitConfiguration()
    self.captureVideoPreviewLayer.session = self.captureSession
    self.startSession()
  }
  
  private func startSession() {
    guard !self.captureSession.isRunning else {
      print("\(Self.self).startSession was called while the session was already running.")
      return
    }
    Task.detached {
      await self.captureSession.startRunning()
    }
  }
  
  private func switchCamera() throws {
    print("switchCamera")
    
    guard let captureDeviceInput else {
      return
    }
    
    self.captureSession.beginConfiguration()
    self.captureSession.removeInput(captureDeviceInput)
    
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
      mediaType: .video,
      position: .unspecified
    )
    
    let newPosition: AVCaptureDevice.Position = captureDeviceInput.device.position == .back
    ? .front
    : .back
    
    guard let newDevice = discoverySession.devices.first(where: { $0.position == newPosition })
    else {
      throw AnyError("Failed to switch camera. Reverting to original.")
    }
    guard let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
      throw AnyError("Failed to create new video device input.")
    }
    guard self.captureSession.canAddInput(newInput) else {
      throw AnyError("Cannot ad input \(newDevice)")
    }
    
    self.captureSession.addInput(newInput)
    self.captureDeviceInput = newInput
    self.captureSession.commitConfiguration()
  }
  
  private func startRecording() throws {
    guard let connection = self.captureMovieFileOutput.connection(with: .video) else {
      throw AnyError("movieOutput.connection(with: .video) returned nil")
    }
    
    // Configure connection for HEVC capture.
    if self.captureMovieFileOutput.availableVideoCodecTypes.contains(.hevc) {
      self.captureMovieFileOutput.setOutputSettings(
        [AVVideoCodecKey: AVVideoCodecType.hevc],
        for: connection
      )
    }
    
    // Enable video stabilization if the connection supports it.
    if connection.isVideoStabilizationSupported {
      connection.preferredVideoStabilizationMode = .auto
    }
    
    self.captureMovieFileOutput.startRecording(
      to: URL.temporaryDirectory
        .appending(component: self.uuid().uuidString)
        .appendingPathExtension(for: .quickTimeMovie),
      recordingDelegate: self.captureFileOutputRecordingDelegate
    )
    self.isRecording = true
  }
  
  private func stopRecording() {
    self.captureMovieFileOutput.stopRecording()
    self.isRecording = false
  }
  
  private func handle(_ event: CaptureFileOutputRecordingDelegate.Event) {
    switch event {
      
    case let .fileOutput(_, outputFileURL, _, _):
      Task.detached {
        try await self.photoLibrary().performChanges({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        })
      }
    }
  }
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable var model: MainModel
  
  var body: some View {
    NavigationStack {
      if self.model.hasFullPermissions {
        self.camera
      } else {
        self.permissionsRequired
      }
    }
    .navigationBarBackButtonHidden()
    .overlay(content: self.overlay)
    .task { await self.model.task() }
    .sheet(item: $model.destination.userPermissions) { model in
      UserPermissionsSheet(model: model)
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
