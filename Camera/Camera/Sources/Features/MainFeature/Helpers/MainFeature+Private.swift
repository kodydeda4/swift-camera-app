import AVFoundation
import Foundation
import Photos

extension MainModel {
 
  internal func _startRecording() -> Void {
    let movieOutput = self.avCaptureMovieFileOutput
    
    guard !self.avCaptureMovieFileOutput.isRecording else {
      self._stopRecording()
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
    
    // Start a timer to update the recording time.
    // ...
    
    //@DEDA
    movieOutput.startRecording(
      to: URL.movieFileOutput(id: self.uuid()),//@DEDA dependency?
      recordingDelegate: self.recordingDelegate
    )
    self.isRecording = true
    print("✅ started recording")
    return
  }
  
  internal func _stopRecording() {
    self.avCaptureMovieFileOutput.stopRecording()
    self.isRecording = false
    print("✅ stopped recording")
    return
  }
  
  func _handleRecordingDelegateEvent(_ event: MovieCaptureDelegate.Event) {
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
  
  /// @DEDA setup the device.
  internal func _request(device value: AVCaptureDevice?) {
    self.avCaptureDevice = value
    
    guard let value else {
      print("❌ requestDefaultAVCaptureDeviceResponse is false")
      return
    }
    
    self.avCaptureDeviceInput = try? AVCaptureDeviceInput(device: value)
    
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
}
