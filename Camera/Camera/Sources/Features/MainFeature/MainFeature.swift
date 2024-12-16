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
          await self.handleRecordingDelegateEvent(event)
        }
      }
    }
  }
}

private extension MainModel {
  
  func bind() {
    switch destination {
      
    case let .userPermissions(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case .none:
      break
    }
  }
  
  func startCaptureSession() throws {
    // 1. Verify device inputs & outputs
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
    
    // 2. State.set
    self.captureDevice = device
    self.captureDeviceInput = input
    self.captureSession.addInput(input)
    self.captureSession.addOutput(output)
    self.captureVideoPreviewLayer.session = self.captureSession
    
    //@DEDA
    Task.detached {
      await self.captureSession.startRunning()
    }
  }
  
  func startRecording() throws {
    guard let connection = self.captureMovieFileOutput.connection(with: .video) else {
      throw AnyError("movieOutput.connection(with: .video) returned nil")
    }
    
    // Configure connection for HEVC capture.
    if self.captureMovieFileOutput.availableVideoCodecTypes.contains(.hevc) {
      self.captureMovieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
    }
    
    // Enable video stabilization if the connection supports it.
    if connection.isVideoStabilizationSupported {
      connection.preferredVideoStabilizationMode = .auto
    }
    
    self.captureMovieFileOutput.startRecording(
      to: .movieFileOutput(uuid()),
      recordingDelegate: self.captureFileOutputRecordingDelegate
    )
  }
  
  func stopRecording() {
    self.captureMovieFileOutput.stopRecording()
  }
  
  func handleRecordingDelegateEvent(_ event: CaptureFileOutputRecordingDelegate.Event) {
    switch event {
      
    case let .fileOutput(
      output,
      didFinishRecordingTo: outputFileURL,
      from: connections,
      error: error
    ):
      print(output, outputFileURL, connections, error as Any)
      
      guard self.userPermissions[.photos] == .authorized else {
        print("photo library read write access not granted.")
        return
      }
      
      //@DEDA ?...
      Task.detached {
        //@DEDA
        try await self.photoLibrary().performChanges({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        })
      }
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
          self.camera
        } else {
          self.permissionsRequired
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
