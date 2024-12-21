import AVFoundation
import Sharing

struct CameraState: Equatable {
  var zoom = 1.0
  var isRecording = false
  var position = AVCaptureDevice.Position.back
  var captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
}

extension SharedReaderKey where Self == InMemoryKey<CameraState>.Default {
  static var camera: Self {
    Self[.inMemory("camera"), default: CameraState()]
  }
}
