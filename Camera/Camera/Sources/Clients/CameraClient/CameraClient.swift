import AsyncAlgorithms
import AVFoundation
import Dependencies
import DependenciesMacros
import Photos
import SwiftUI
import SwiftUINavigation

@DependencyClient
struct CameraClient: Sendable {
  var connect: @Sendable (AVCaptureVideoPreviewLayer) throws -> Void
  var startRecording: @Sendable (URL) throws -> Void
  var stopRecording: @Sendable () throws -> Void
  var switchCamera: @Sendable () throws -> Void
  var zoom: @Sendable (CGFloat) throws -> Void
  var events: @Sendable () -> AsyncChannel<DelegateEvent> = { .init() }
  
  struct Failure: Error, Equatable {
    var rawValue: String
    
    init(_ rawValue: String = "") { self.rawValue = rawValue }
    
    static var cannotAddInput = Failure("Cannot add input")
    static var cannotAddOutput = Failure("Cannot add input")
    static var cannotMakeDeviceInput = Failure("Cannot make device input")
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

// @DEDA implement Log4Swift

extension CameraClient: DependencyKey {
  static var liveValue: Self {
    let camera = Camera.shared
    
    return Self(
      connect: { preview in
        let result = Result { try camera.connect(preview) }
        print("connect", result)
        return try result.get()
      },
      startRecording: { url in
        let result = Result { try camera.startRecording(to: url) }
        print("startRecording", result)
        return try result.get()
      },
      stopRecording: {
        let result = Result { camera.stopRecording() }
        print("stopRecording", result)
        return try result.get()
      },
      switchCamera: {
        let result = Result { try camera.switchCamera() }
        print("switchCamera", result)
        return try result.get()
      },
      zoom: { newValue in
        let result = Result { try camera.zoom(newValue) }
        print("zoom", result)
        return try result.get()
      },
      events: {
        camera.events
      }
    )
  }
}

fileprivate final class Camera: NSObject {
  
  // @DEDA PointFree error handling with line number?...
  
  static let shared = Camera()
  let events = AsyncChannel<CameraClient.DelegateEvent>()

  private var session = AVCaptureSession()
  private var device: AVCaptureDevice?
  private var deviceInput: AVCaptureDeviceInput?
  private var movieFileOutput = AVCaptureMovieFileOutput()

  func connect(_ videoPreviewLayer: AVCaptureVideoPreviewLayer) throws {
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let deviceInput = try? AVCaptureDeviceInput(device: device)
    else { throw CameraClient.Failure("Couldn't setup inputs.") }
    
    self.session.beginConfiguration()
    guard self.session.canAddInput(deviceInput) else { throw CameraClient.Failure.cannotAddInput }
    guard self.session.canAddOutput(self.movieFileOutput) else { throw CameraClient.Failure.cannotAddOutput }
    self.session.addInput(deviceInput)
    self.session.addOutput(self.movieFileOutput)
    self.session.commitConfiguration()
    self.device = device
    self.deviceInput = deviceInput

    videoPreviewLayer.session = self.session

    Task.detached {
      self.session.startRunning()
    }
  }

  /// Switch between front & back camera.
  func switchCamera() throws {
    guard let deviceInput else { return }
    
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
      mediaType: .video,
      position: deviceInput.device.position == .back ? .front : .back
    )
    
    guard
      let newDevice = discoverySession.devices.first,
      let newDeviceInput = try? AVCaptureDeviceInput(device: newDevice)
    else { throw CameraClient.Failure.cannotMakeDeviceInput }
    
    self.session.beginConfiguration()
    self.session.removeInput(deviceInput)
    guard self.session.canAddInput(newDeviceInput) else { throw CameraClient.Failure.cannotAddInput }
    self.session.addInput(newDeviceInput)
    self.deviceInput = newDeviceInput
    self.session.commitConfiguration()
  }
  
  /// Adjust the zoom - may require switching cameras.
  func zoom(_ videoZoomFactor: CGFloat) throws {
    guard let device, let deviceInput else {
      return
    }
    
    let newDeviceType = !(videoZoomFactor < 1 && device.deviceType == .builtInWideAngleCamera)
    ? AVCaptureDevice.DeviceType.builtInWideAngleCamera
    : AVCaptureDevice.DeviceType.builtInUltraWideCamera
    
    let newVideoZoomFactor = newDeviceType == .builtInUltraWideCamera ? 1 : videoZoomFactor
    
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [newDeviceType],
      mediaType: .video,
      position: device.position
    )
    
    guard
      let newDevice = discoverySession.devices.first,
      let newInput = try? AVCaptureDeviceInput(device: newDevice)
    else { throw CameraClient.Failure.cannotMakeDeviceInput }
    
    self.session.beginConfiguration()
    self.session.removeInput(deviceInput)
    guard self.session.canAddInput(newInput)
    else { throw CameraClient.Failure.cannotAddInput }
    self.session.addInput(newInput)
    self.deviceInput = newInput
    self.session.commitConfiguration()
    
    // update
    try self.device?.lockForConfiguration()
    self.device?.videoZoomFactor = newVideoZoomFactor
    self.device?.unlockForConfiguration()
  }
  
  /// Start recording video to a url.
  func startRecording(to url: URL) throws {
    guard let connection = self.movieFileOutput.connection(with: .video)
    else { throw CameraClient.Failure() }
    
    // Configure connection for HEVC capture.
    if self.movieFileOutput.availableVideoCodecTypes.contains(.hevc) {
      self.movieFileOutput.setOutputSettings(
        [AVVideoCodecKey: AVVideoCodecType.hevc],
        for: connection
      )
    }
    
    // Enable video stabilization if the connection supports it.
    if connection.isVideoStabilizationSupported {
      connection.preferredVideoStabilizationMode = .auto
    }
    
    self.movieFileOutput.startRecording(to: url, recordingDelegate: self)
  }
  
  func stopRecording() {
    self.movieFileOutput.stopRecording()
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
