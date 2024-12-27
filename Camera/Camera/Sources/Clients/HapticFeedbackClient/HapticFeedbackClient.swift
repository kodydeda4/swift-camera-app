import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct HapticFeedbackClient: Sendable {
  var generate: @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) async -> Void
}

extension DependencyValues {
  var hapticFeedback: HapticFeedbackClient {
    get { self[HapticFeedbackClient.self] }
    set { self[HapticFeedbackClient.self] = newValue }
  }
}

extension HapticFeedbackClient: DependencyKey {
  static var liveValue = Self {
    UIImpactFeedbackGenerator(style: $0).impactOccurred()
  }
}
