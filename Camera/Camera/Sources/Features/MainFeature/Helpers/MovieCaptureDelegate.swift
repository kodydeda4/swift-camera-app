import AsyncAlgorithms
import AVFoundation

public final class CaptureFileOutputRecordingDelegate: NSObject {
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

// MARK: - Computed Properties

extension CaptureFileOutputRecordingDelegate: AVCaptureFileOutputRecordingDelegate {
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
