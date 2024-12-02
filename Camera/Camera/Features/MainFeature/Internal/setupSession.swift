import AVFoundation

extension MainModel {
  func startCaptureSession(with device: AVCaptureDevice?) {
    self.avCaptureDevice = device
    
    guard let device else {
      print("❌ requestDefaultAVCaptureDeviceResponse is false")
      return
    }
    
    self.avCaptureDeviceInput = try? AVCaptureDeviceInput(device: device)
    
    guard let input = self.avCaptureDeviceInput else {
      print("❌ avCaptureDeviceInput is nil")
      return
    }
    
    let output = self.avCaptureMovieFileOutput
    
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
    
    Task.detached {
      await self.avCaptureSession.startRunning()
    }
  }
}
