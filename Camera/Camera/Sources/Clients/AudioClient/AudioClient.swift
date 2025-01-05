import AudioToolbox
import AVFoundation
import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct AudioClient: Sendable {
  var recordPermission: @Sendable () -> AVAudioApplication.recordPermission = { .undetermined }
  var requestRecordPermission: @Sendable () async -> Bool = { false }
  var play: @Sendable (SystemSound) -> Void
}

extension DependencyValues {
  var audio: AudioClient {
    get { self[AudioClient.self] }
    set { self[AudioClient.self] = newValue }
  }
}

extension AudioClient: DependencyKey {
  static var liveValue = Self(
    recordPermission: {
      AVAudioApplication.shared.recordPermission
    },
    requestRecordPermission: {
      await AVAudioApplication.requestRecordPermission()
    },
    play: { systemSound in
      AudioServicesPlaySystemSound(SystemSoundID(systemSound.rawValue))
    }
  )
}
