import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct HapticFeedbackClient {
  var generate: (UIImpactFeedbackGenerator.FeedbackStyle) -> Void
}

extension DependencyValues {
  var hapticFeedback: HapticFeedbackClient {
    get { self[HapticFeedbackClient.self] }
    set { self[HapticFeedbackClient.self] = newValue }
  }
}

extension HapticFeedbackClient: DependencyKey {
  static var liveValue: Self {
    return Self {
      UIImpactFeedbackGenerator(style: $0).impactOccurred()
    }
  }
}
