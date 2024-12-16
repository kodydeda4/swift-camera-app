import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation
import AVFoundation

@MainActor
@Observable
final class MainModel {
  internal var isRecording = false
  internal let avCaptureSession = AVCaptureSession()
  internal var avCaptureDevice: AVCaptureDevice?
  internal var avCaptureDeviceInput: AVCaptureDeviceInput?
  internal var avCaptureMovieFileOutput = AVCaptureMovieFileOutput()
  internal let avVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  internal var recordingDelegate = CaptureFileOutputRecordingDelegate()
  
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored
  @Shared(.userPermissions) var userPermissions
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissionsClient
  
  @ObservationIgnored
  @Dependency(\.photoLibrary) var photoLibrary
  
  @ObservationIgnored
  @Dependency(\.uuid) var uuid
  
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
    !self.isRecording ? self.startRecording() : self.stopRecording()
    self.isRecording.toggle()
  }
  
  func settingsButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }

  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.setupCaptureSession(for: AVCaptureDevice.default(for: .video))
      }
      taskGroup.addTask {
        for await event in await self.recordingDelegate.events {
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
  
  func setupCaptureSession(for device: AVCaptureDevice?) {
    self.avCaptureDevice = device
    
    guard let device else {
      print("❌ requestDefaultAVCaptureDeviceResponse is false")
      return
    }
    
    self.avCaptureDeviceInput = try? AVCaptureDeviceInput(device: device)
    
    guard let input = avCaptureDeviceInput else {
      print("❌ avCaptureDeviceInput is nil")
      return
    }
    let output = avCaptureMovieFileOutput
    //          guard let output = state.avCaptureDeviceOutput else {
    //            print("❌ avCaptureDeviceOutput is nil")
    //            return .none
    //          }
    
    print("✅ input and output are non-nil")
    
    if self.avCaptureSession.canAddInput(input) {
      self.avCaptureSession.addInput(input)
      print("✅ added input")
    }
    if self.avCaptureSession.canAddOutput(output) {
      self.avCaptureSession.addOutput(output)
      print("✅ added output")
    }
    self.avVideoPreviewLayer.session = self.avCaptureSession
    
    //@DEDA
    Task.detached {
      await self.avCaptureSession.startRunning()
      print("✅ captureSession.startRunning()")
    }
  }

  func startRecording() -> Void {
    let movieOutput = self.avCaptureMovieFileOutput
    
    guard !self.avCaptureMovieFileOutput.isRecording else {
      self.stopRecording()
      return
    }
    
    guard let connection = movieOutput.connection(with: .video) else {
      print("❌ Configuration error. No video connection found")
      return
    }
    
    // Configure connection for HEVC capture.
    if movieOutput.availableVideoCodecTypes.contains(.hevc) {
      movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
    }
    
    // Enable video stabilization if the connection supports it.
    if connection.isVideoStabilizationSupported {
      connection.preferredVideoStabilizationMode = .auto
    }
    
    movieOutput.startRecording(
      to: URL.movieFileOutput(id: self.uuid()),
      recordingDelegate: self.recordingDelegate
    )
    
    self.isRecording = true
    print("✅ started recording")
    return
  }
  
  func stopRecording() {
    self.avCaptureMovieFileOutput.stopRecording()
    self.isRecording = false
    print("✅ stopped recording")
    return
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
