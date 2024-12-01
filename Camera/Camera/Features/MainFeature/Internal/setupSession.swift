import AVFoundation

extension MainModel {
  internal func handle(request device: AVCaptureDevice?) {
    let result = Result {
      try self.setupSession(with: device)
    }
    print("\(Self.self).setupSession", result)
  }
  
  internal func setupSession(with device: AVCaptureDevice?) throws {
    guard let device
    else { throw AnyError("❌ avCaptureDevice is nil") }
    
    let output = self.avCaptureMovieFileOutput

    guard let input = try? AVCaptureDeviceInput(device: device)
    else { throw AnyError("❌ avCaptureDeviceInput is nil") }
    
    guard self.avCaptureSession.canAddInput(input)
    else { throw AnyError("❌ cannot add input") }
    
    guard self.avCaptureSession.canAddOutput(output)
    else { throw AnyError("❌ cannot add output") }

    self.avCaptureDevice = device
    self.avCaptureDeviceInput = input
    self.avCaptureSession.addInput(input)
    self.avCaptureSession.addOutput(output)
    
    Task.detached {
      await self.avCaptureSession.startRunning()
    }
  }
}
