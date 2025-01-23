import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct ApplicationClient {
  var open: (URL) -> Void
}

extension DependencyValues {
  var application: ApplicationClient {
    get { self[ApplicationClient.self] }
    set { self[ApplicationClient.self] = newValue }
  }
}

extension ApplicationClient: DependencyKey {
  static var liveValue: Self {
    return Self {
      UIApplication.shared.open($0, options: [:], completionHandler: nil)
    }
  }
}
