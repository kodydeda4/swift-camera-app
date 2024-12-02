import AVFoundation

extension CaptureSessionModel {
  internal func stopRecording() {
    avCaptureMovieFileOutput.stopRecording()
    isRecording = false
    // state.delegate = .none
    print("✅ stopped recording")
    // state.isRecording = false
    return
  }
}

