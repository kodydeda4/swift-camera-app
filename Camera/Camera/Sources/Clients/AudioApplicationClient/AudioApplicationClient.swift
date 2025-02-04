import AudioToolbox
import AVFoundation
import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct AudioApplicationClient: Sendable {
  var recordPermission: @Sendable () -> AVAudioApplication.recordPermission = { .undetermined }
  var requestRecordPermission: @Sendable () async -> Bool = { false }
}

extension DependencyValues {
  var audioApplication: AudioApplicationClient {
    get { self[AudioApplicationClient.self] }
    set { self[AudioApplicationClient.self] = newValue }
  }
}

extension AudioApplicationClient: DependencyKey {
  static var liveValue = Self(
    recordPermission: {
      AVAudioApplication.shared.recordPermission
    },
    requestRecordPermission: {
      await AVAudioApplication.requestRecordPermission()
    }
  )
}
