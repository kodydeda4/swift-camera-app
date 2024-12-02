import AVFoundation

extension CaptureSessionModel {
  
  internal func startRecording() {
    let movieOutput = self.avCaptureMovieFileOutput
    
    guard !movieOutput.isRecording else {
      return self.stopRecording()
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
      to: URL.movieFileOutput(id: UUID()),
      recordingDelegate: recordingDelegate
    )
    isRecording = true
    print("✅ started recording")
    return
  }
}
