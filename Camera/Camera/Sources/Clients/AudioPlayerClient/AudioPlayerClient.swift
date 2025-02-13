import AudioToolbox
import AVFoundation
import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct AudioPlayerClient: Sendable {
  var play: @Sendable (SystemSound) -> Void
}

extension DependencyValues {
  var audioPlayer: AudioPlayerClient {
    get { self[AudioPlayerClient.self] }
    set { self[AudioPlayerClient.self] = newValue }
  }
}

extension AudioPlayerClient: DependencyKey {
  static var liveValue = Self { systemSound in
    AudioServicesPlaySystemSound(SystemSoundID(systemSound.rawValue))
  }
}
