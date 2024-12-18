import AsyncAlgorithms
import AVFoundation

final class CaptureFileOutputRecordingDelegate: NSObject {
  let events = AsyncChannel<Event>()

  enum Event {
    case fileOutput(
      _ output: AVCaptureFileOutput,
      didFinishRecordingTo: URL,
      from: [AVCaptureConnection],
      error: Error?
    )
  }
}

// MARK: - Computed Properties

extension CaptureFileOutputRecordingDelegate: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    Task {
      await events.send(.fileOutput(
        output,
        didFinishRecordingTo: outputFileURL,
        from: connections,
        error: error
      ))
    }
  }
}
