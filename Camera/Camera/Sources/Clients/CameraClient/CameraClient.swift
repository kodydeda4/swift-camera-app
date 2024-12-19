import AsyncAlgorithms
import AVFoundation
import Dependencies
import Dependencies
import DependenciesMacros
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@DependencyClient
struct CameraClient: Sendable {
  var startRecording: @Sendable (URL) -> Void
  var stopRecording: @Sendable () -> Void
  var switchCamera: @Sendable () -> Void
  var zoom: @Sendable (CGFloat) -> Void
  var events: @Sendable () -> AsyncChannel<DelegateEvent> = { .init() }
  
  struct State: Equatable {
    var zoom = 1.0
    var isRecording = false
    var captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  }
  
  struct Failure: Error, Equatable {
    let rawValue: String
  }
  
  enum DelegateEvent {
    case captureFileOutputRecording(CaptureFileOutputRecording)
    
    enum CaptureFileOutputRecording {
      case fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo: URL,
        from: [AVCaptureConnection],
        error: Error?
      )
    }
  }
}

extension SharedReaderKey where Self == InMemoryKey<CameraClient.State>.Default {
  static var camera: Self {
    Self[.inMemory("camera"), default: CameraClient.State()]
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
    let camera = Camera.shared
    
    return Self(
      startRecording: { url in
        let result = Result { try camera.startRecording(to: url) }
        print(result)
      },
      stopRecording: {
        camera.stopRecording()
      },
      switchCamera: {
        let result = Result { try camera.switchCamera() }
        print(result)
      },
      zoom: { newValue in
        let result = Result { try camera.zoom(newValue) }
        print(result)
      },
      events: {
        camera.events
      }
    )
  }
}

fileprivate final class Camera: NSObject {
  static let shared = Camera()
  let events = AsyncChannel<CameraClient.DelegateEvent>()
  @Shared(.camera) var camera

  private var captureSession = AVCaptureSession()
  private var captureDevice: AVCaptureDevice?
  private var captureDeviceInput: AVCaptureDeviceInput?
  private var captureMovieFileOutput = AVCaptureMovieFileOutput()
  
  override init() {
    super.init()
    
    do {
      try self.configureCaptureSession()
    } catch {
      print(error.localizedDescription)
    }
  }
  
  private func configureCaptureSession() throws {
    self.captureSession.beginConfiguration()
    
    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    let output = self.captureMovieFileOutput
    
    guard let device else {
      throw CameraClient.Failure(rawValue: "\(String(describing: device)) returned nil.")
    }
    guard let input = try? AVCaptureDeviceInput(device: device) else {
      throw CameraClient.Failure(rawValue: "Could not create input for \(device)")
    }
    guard self.captureSession.canAddInput(input) else {
      throw CameraClient.Failure(rawValue: "self.avCaptureSession.canAddInput(input) returned false.")
    }
    guard self.captureSession.canAddOutput(output) else {
      throw CameraClient.Failure(rawValue: "self.avCaptureSession.canAddOutput(output) returned false.")
    }
    
    self.captureDevice = device
    self.captureDeviceInput = input
    self.captureSession.addInput(input)
    self.captureSession.addOutput(output)
    self.captureSession.commitConfiguration()
    self.$camera.captureVideoPreviewLayer.withLock { $0.session = self.captureSession }
    self.captureSession.startRunning()
  }

  func switchCamera() throws {
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
    
    var newPosition: AVCaptureDevice.Position {
      captureDeviceInput.device.position == .back ? .front : .back
    }
    
    guard let newDevice = discoverySession.devices.first(where: { $0.position == newPosition })
    else {
      throw CameraClient.Failure(rawValue: "Failed to switch camera. Reverting to original.")
    }
    guard let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
      throw CameraClient.Failure(rawValue: "Failed to create new video device input.")
    }
    guard self.captureSession.canAddInput(newInput) else {
      throw CameraClient.Failure(rawValue: "Cannot ad input \(newDevice)")
    }
    
    self.captureSession.addInput(newInput)
    self.captureDeviceInput = newInput
    self.captureSession.commitConfiguration()
  }
  
  func zoom(_ zoomFactor: CGFloat) throws {
    //    @DEDA
    //    The minimum "zoomFactor" property of an AVCaptureDevice can't be less than 1.0 according to the Apple Docs.
    //    It's a little confusing becuase depending on what camera you've selected, a zoom factor of 1 will be a different field of view or optical view angle.
    //    The default iPhone camera app shows a label reading "0.5" but that's just a label for the ultra wide lens in relation to the standard camera's zoom factor.
    //
    //    You're already getting the minZoomFactor from the device, (which will probably be 1),
    //    so you should use the device's min and max that you're reading to set the bounds of the factor you input into "captureDevice.videoZoomFactor".
    //    Then when you;ve selected the ultra wide lens, setting the zoomfactor to 1 will be as wide as you can go!
    //    (a factor of 0.5 in relation to the standard lens's field of view).
    
    guard let captureDevice else { return }
    guard let captureDeviceInput else { return }
    
    try captureDevice.lockForConfiguration()
    
    var newDeviceType: AVCaptureDevice.DeviceType {
      // Camera supporting 0.5 == .builtInUltraWideCamera
      guard !(zoomFactor < 1 && captureDevice.deviceType == .builtInWideAngleCamera) else {
        return .builtInUltraWideCamera
      }
      
      // Else use .builtInWideAngleCamera
      return .builtInWideAngleCamera
    }
    
    var newZoomFactor: CGFloat {
      switch newDeviceType {
      case .builtInUltraWideCamera: return 1
      default: return zoomFactor
      }
    }
    
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [newDeviceType],
      mediaType: .video,
      position: captureDevice.position
    )
    
    print(discoverySession)
    
    guard let newDevice = discoverySession.devices.first else {
      throw CameraClient.Failure(rawValue: "Couldn't find a better device.")
    }
    
    let newInput = try AVCaptureDeviceInput(device: newDevice)
    
    self.captureSession.beginConfiguration()
    self.captureSession.removeInput(captureDeviceInput)
    
    guard self.captureSession.canAddInput(newInput) else {
      throw CameraClient.Failure(rawValue: "Cannot add input \(newDevice)")
    }
    
    self.captureSession.addInput(newInput)
    self.captureDeviceInput = newInput
    self.captureSession.commitConfiguration()
    captureDevice.videoZoomFactor = newZoomFactor
    captureDevice.unlockForConfiguration()
    self.$camera.zoom.withLock { $0 = zoomFactor }
  }
  
  func startRecording(to url: URL) throws {
    guard let connection = self.captureMovieFileOutput.connection(with: .video) else {
      throw CameraClient.Failure(rawValue: "movieOutput.connection(with: .video) returned nil")
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
      to: url,
      recordingDelegate: self
    )
    self.$camera.isRecording.withLock { $0 = true }
  }
  
  func stopRecording() {
    self.captureMovieFileOutput.stopRecording()
    self.$camera.isRecording.withLock { $0 = false }
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
      await events.send(.captureFileOutputRecording(.fileOutput(
        output,
        didFinishRecordingTo: outputFileURL,
        from: connections,
        error: error
      )))
    }
  }
}
