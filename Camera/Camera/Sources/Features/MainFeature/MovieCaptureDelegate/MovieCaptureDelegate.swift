import AVFoundation
import AsyncAlgorithms

public final class MovieCaptureDelegate: NSObject {
  public let events = AsyncChannel<Event>()
  
  public enum Event {
    case fileOutput(
      _ output: AVCaptureFileOutput,
      didFinishRecordingTo: URL,
      from: [AVCaptureConnection],
      error: Error?
    )
  }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension MovieCaptureDelegate: AVCaptureFileOutputRecordingDelegate {
  public func fileOutput(
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
