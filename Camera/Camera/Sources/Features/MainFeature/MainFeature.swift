import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

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
  
  func recordingButtonTapped() {
    try? !isRecording ? startRecording() : stopRecording()
    self.isRecording.toggle()
  }
  
  func permissionsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func switchCameraButtonTapped() {
    //...
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
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        do {
          try await self.startCaptureSession()
        } catch {
          print(error.localizedDescription)
        }
      }
      taskGroup.addTask {
        for await event in await self.captureFileOutputRecordingDelegate.events {
          await self.handle(event)
        }
      }
    }
  }
  
  // MARK: - Private
  
  private func startCaptureSession() throws {
    guard let device = AVCaptureDevice.default(for: .video) else {
      throw AnyError("AVCaptureDevice.default(for: .video) returned nil.")
    }
    
    let input = try AVCaptureDeviceInput(device: device)
    let output = self.captureMovieFileOutput
    
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
    self.captureVideoPreviewLayer.session = self.captureSession
    
    Task.detached {
      await self.captureSession.startRunning()
    }
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
  }
  
  private func stopRecording() {
    self.captureMovieFileOutput.stopRecording()
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
      ZStack {
        Group {
          if self.model.hasFullPermissions {
            self.camera
          } else {
            self.permissionsRequired
          }
        }
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
