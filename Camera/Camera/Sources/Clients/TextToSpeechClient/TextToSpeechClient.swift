import Dependencies
import DependenciesMacros
import AVFoundation

@DependencyClient
public struct TextToSpeechClient {
  var speak: (AVSpeechUtterance) -> Void = { _ in }
  var speakAsync: (AVSpeechUtterance) async -> Void = { _ in }
}

public extension DependencyValues {
  var textToSpeech: TextToSpeechClient {
    get { self[TextToSpeechClient.self] }
    set { self[TextToSpeechClient.self] = newValue }
  }
}

// MARK: - Implementation

extension TextToSpeechClient: DependencyKey {
  //@DEDA you need to add loggers.
  public static var liveValue: Self {
//    let log = Loggers.textToSpeechClient
    let synthesizer = AVSpeechSynthesizer()
    let delegate = Delegate()
    
    return Self(
      speak: { utterance in
//        log.info("speak(\(utterance))")
        print("speak(\(utterance))")
        synthesizer.speak(utterance)
      },
      speakAsync: { utterance in
//        log.info("speakAsync(\(utterance)")
        print("speakAsync(\(utterance)")
        await withCheckedContinuation { continuation in
          delegate.continuation = continuation
          synthesizer.delegate = delegate
          synthesizer.speak(utterance)
        }
      }
    )
    
    final class Delegate: NSObject, AVSpeechSynthesizerDelegate {
      var continuation: CheckedContinuation<Void, Never>?

      func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        continuation?.resume()
        continuation = .none
      }
    }
  }
}

public extension AVSpeechUtterance {
  /// Create an `AVSpeechUtterance` with default properties.
  static var `default`: (String) -> AVSpeechUtterance = {
    let rv = AVSpeechUtterance(string: $0)
    rv.rate = 0.5
    rv.voice = {
      let samantha = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name == "Samantha" })
      let englishUS = AVSpeechSynthesisVoice(language: "en-US")
      return samantha ?? englishUS.unsafelyUnwrapped
    }()
    return rv
  }
}

