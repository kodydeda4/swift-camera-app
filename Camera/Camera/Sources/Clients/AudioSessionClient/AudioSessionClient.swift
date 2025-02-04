import Dependencies
import DependenciesMacros
import AVFoundation
import Combine

/// `AVAudioSession` dependency that allows you to configure audio for the app.
@DependencyClient
public struct AudioSessionClient {

  internal var _configure: (Self.Configuration) throws -> Void

  /// Configure the audio session.
  /// - Hint: Call this method on startup.
  func configure(for newValue: Self.Configuration = .default) throws {
    try self._configure(newValue)
  }

  struct Configuration: Identifiable, Equatable {
    let id: String
    let category: AVAudioSession.Category
    let mode: AVAudioSession.Mode
    let options: AVAudioSession.CategoryOptions
    let allowHapticsAndSystemSoundsDuringRecording = true
  }
}

extension AudioSessionClient.Configuration {

  /// The default configuration.
  static let `default` = Self.videoRecording

  /// The configuration used for video recording.
  static let videoRecording = AudioSessionClient.Configuration(
    id: "videoRecording",
    category: .playAndRecord,
    mode: .videoRecording,
    options: [
      .mixWithOthers,
      .allowAirPlay,
      .allowBluetooth,
      .allowBluetoothA2DP,
    ]
  )

  /// The configuration used for movie playback within the app.
  static let moviePlayback = AudioSessionClient.Configuration(
    id: "moviePlayback",
    category: .playback,
    mode: .moviePlayback,
    options: [
      .duckOthers,
      .allowAirPlay,
      .allowBluetooth,
      .allowBluetoothA2DP,
    ]
  )
}

public extension DependencyValues {
  var audioSession: AudioSessionClient {
    get { self[AudioSessionClient.self] }
    set { self[AudioSessionClient.self] = newValue }
  }
}

// MARK: - Implementation

extension AudioSessionClient: DependencyKey {
  public static var liveValue = Self { config in
    let result = Result {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setActive(false)

      try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(
        config.allowHapticsAndSystemSoundsDuringRecording
      )

      try audioSession.setCategory(
        config.category,
        mode: config.mode,
        options: config.options
      )

      try audioSession.setActive(true)

      if config != .moviePlayback {
        // Notify extenrnal apps to resume playback.
        NotificationCenter.default.post(Notification(
          name: AVAudioSession.interruptionNotification,
          userInfo: [
            AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionType.ended
          ]
        ))
      }
    }
    //@DEDA log
     print("configure.\(config.id).\(result)")
//    Loggers.audioSessionClient.info("configure.\(config.id).\(result)")
    return try result.get()
  }
}
