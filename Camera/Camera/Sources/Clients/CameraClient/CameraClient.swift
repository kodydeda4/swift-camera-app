import AsyncAlgorithms
import AVFoundation
import Dependencies
import DependenciesMacros
import Photos
import SwiftUI
import SwiftUINavigation

@DependencyClient
struct CameraClient: Sendable {
  var requestAccess: @Sendable (AVMediaType) async -> Bool = { _ in false }
  var authorizationStatus: @Sendable (AVMediaType) -> AVAuthorizationStatus = { _ in
    .notDetermined
  }
  var connect: @Sendable (AVCaptureVideoPreviewLayer) throws -> Void
  var startRecording: @Sendable (URL) throws -> Void
  var stopRecording: @Sendable () throws -> Void
  var adjust: @Sendable (CameraSetting) throws -> Void
  var events: @Sendable () -> AsyncChannel<DelegateEvent> = { .init() }
  
  enum CameraSetting: Equatable {
    case position(AVCaptureDevice.Position)
    case torchMode(AVCaptureDevice.TorchMode)
    case videoZoomFactor(CGFloat)
  }

  enum Failure: Error, Equatable {
    case custom(String)
    case cannotAddInput
    case cannotAddOutput
    case cannotMakeDeviceInput
  }
  
  enum DelegateEvent {
    case avCaptureFileOutputRecordingDelegate(Self.AVCaptureFileOutputRecordingDelegate)
    
    enum AVCaptureFileOutputRecordingDelegate {
      case fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo: URL,
        from: [AVCaptureConnection],
        error: Error?
      )
    }
  }
}

extension DependencyValues {
  var camera: CameraClient {
    get { self[CameraClient.self] }
    set { self[CameraClient.self] = newValue }
  }
}

// MARK: - Implementation

extension CameraClient: DependencyKey {
  static var liveValue: Self {
    let camera = Camera()
    
    return Self(
      requestAccess: { mediaType in
        await AVCaptureDevice.requestAccess(for: mediaType)
      },
      authorizationStatus: { mediaType in
        AVCaptureDevice.authorizationStatus(for: mediaType)
      },
      connect: { videoPreviewLayer in
        try camera.connect(to: videoPreviewLayer)
      },
      startRecording: { url in
        try camera.startRecording(to: url)
      },
      stopRecording: {
        camera.stopRecording()
      },
      adjust: { value in
        try camera.adjust(setting: value)
      },
      events: {
        camera.events
      }
    )
  }
}

fileprivate final class Camera: NSObject {
  let events = AsyncChannel<CameraClient.DelegateEvent>()
  
  private var session: AVCaptureSession!
  private var movieFileOutput: AVCaptureMovieFileOutput!
  private var videoDevice: AVCaptureDevice!
  private var videoDeviceInput: AVCaptureDeviceInput!
  private var audioDevice: AVCaptureDevice!
  private var audioDeviceInput: AVCaptureDeviceInput!
  
  /// Sets up the capture session with necessary inputs and outputs,
  /// connects to the video preview layer, and starts running the capture session in the background.
  ///
  /// - Note: This method is required to enable the functionality of other methods within the class.
  /// - Note: Ensure that user permissions (e.g., camera and microphone) are verified before invoking this method.
  func connect(to videoPreviewLayer: AVCaptureVideoPreviewLayer) throws {
    self.session = AVCaptureSession()
    self.movieFileOutput = AVCaptureMovieFileOutput()
    
    guard
      let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
      let audioDevice = AVCaptureDevice.default(for: .audio),
      let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
      self.session.canAddInput(videoDeviceInput),
      self.session.canAddInput(audioDeviceInput),
      self.session.canAddOutput(movieFileOutput)
    else { throw CameraClient.Failure.custom("Failed to setup initial devices.") }

    print("Session.Configure.start")
    self.session.beginConfiguration()
    self.session.addInput(videoDeviceInput)
    self.session.addInput(audioDeviceInput)
    self.session.addOutput(movieFileOutput)
    self.session.commitConfiguration()
    print("Session.Configure.finish")
    
    self.videoDevice = videoDevice
    self.videoDeviceInput = videoDeviceInput
    self.audioDevice = audioDevice
    self.audioDeviceInput = audioDeviceInput

    Task.detached {
      print("Task.detached")
      self.session.startRunning()
    }
    
    videoPreviewLayer.session = self.session
  }
  
  /// Start recording video to a url.
  func startRecording(to url: URL) throws {
    guard let connection = self.movieFileOutput.connection(with: .video) else {
      throw CameraClient.Failure.custom("self.movieFileOutput.connection(with: .video) was nil")
    }
    
    if self.movieFileOutput.availableVideoCodecTypes.contains(.hevc) {
      self.movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
    }
    
    if connection.isVideoStabilizationSupported {
      connection.preferredVideoStabilizationMode = .auto
    }
    
    self.movieFileOutput.startRecording(to: url, recordingDelegate: self)
  }
  
  func stopRecording() {
    self.movieFileOutput.stopRecording()
  }
  
  func adjust(setting: CameraClient.CameraSetting) throws {
    switch setting {
    case let .torchMode(value): try setTorchMode(value)
    case let .position(value): try setPosition(value)
    case let .videoZoomFactor(value): try setVideoZoomFactor(value)
    }
  }

  private func setPosition(_ newPosition: AVCaptureDevice.Position) throws {
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video,
      position: newPosition
    )
    
    guard
      let newVideoDevice = discoverySession.devices.first,
      let newVideoInput = try? AVCaptureDeviceInput(device: newVideoDevice)
    else {
      throw CameraClient.Failure.cannotMakeDeviceInput
    }
    
    self.session.beginConfiguration()
    self.session.removeInput(videoDeviceInput)
    
    guard self.session.canAddInput(newVideoInput) else {
      throw CameraClient.Failure.cannotAddInput
    }
    
    self.session.addInput(newVideoInput)
    self.videoDeviceInput = newVideoInput
    self.session.commitConfiguration()
    return
  }

  /// Adjust the zoom - may require switching cameras.
  private func setVideoZoomFactor(_ videoZoomFactor: CGFloat) throws {
    var newVideoDevice: AVCaptureDevice? {
      AVCaptureDevice.DiscoverySession(
        deviceTypes: [videoZoomFactor < 1 ? .builtInUltraWideCamera : .builtInWideAngleCamera],
        mediaType: .video,
        position: videoDevice.position
      )
      .devices.first
    }
    
    guard let newVideoDevice, let newVideoInput = try? AVCaptureDeviceInput(device: newVideoDevice) else {
      throw CameraClient.Failure.cannotMakeDeviceInput
    }
    
    // session configure
    self.session.beginConfiguration()
    self.session.removeInput(videoDeviceInput)
    
    guard self.session.canAddInput(newVideoInput) else {
      throw CameraClient.Failure.cannotAddInput
    }
    
    self.session.addInput(newVideoInput)
    self.videoDeviceInput = newVideoInput
    self.session.commitConfiguration()
    
    // device configure
    try self.videoDevice.lockForConfiguration()
    self.videoDevice.videoZoomFactor = newVideoDevice.deviceType == .builtInUltraWideCamera
      ? 1
      : videoZoomFactor
    self.videoDevice.unlockForConfiguration()
  }
  
  private func setTorchMode(_ torchMode: AVCaptureDevice.TorchMode) throws {
    guard videoDevice.hasTorch else {
      throw CameraClient.Failure.custom("device does not have a torch.")
    }
    
    try self.videoDevice.lockForConfiguration()
    
    if videoDevice.isTorchModeSupported(.on) {
      videoDevice.torchMode = torchMode
    }
    
    self.videoDevice.unlockForConfiguration()
  }
}

extension Camera: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    Task {
      await events.send(.avCaptureFileOutputRecordingDelegate(.fileOutput(
        output,
        didFinishRecordingTo: outputFileURL,
        from: connections,
        error: error
      )))
    }
  }
}
