import AVFoundation
import Sharing

//@DEDA
// you can probably fix a bunch of bugs if you hold onto AVCaptureDevice or smthn.
// when you switch cameras, you forget the previous setup, so when you switch back and forth the ui has not been updated with the correct zoom etc.
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
