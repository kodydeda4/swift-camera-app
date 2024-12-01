import AVFoundation

extension MainModel {
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
    
    //@DEDA probably here man.
    print("Starting session on thread: \(Thread.current)")
    self.avCaptureSession.startRunning()
    print("isRunning", self.avCaptureSession.isRunning)
  }
}
