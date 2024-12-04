import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct ApplicationClient: Sendable {
  var openSettings: @Sendable () async throws -> Void
}

extension ApplicationClient: DependencyKey {
  static var liveValue: ApplicationClient {
    return Self(
      openSettings: {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          throw AnyError("UIApplication.openSettingsURLString")
        }
        guard await UIApplication.shared.canOpenURL(url) else {
          throw AnyError("UIApplication.shared.canOpenURL")
        }
        await UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    )
  }
}

extension DependencyValues {
  var application: ApplicationClient {
    get { self[ApplicationClient.self] }
    set { self[ApplicationClient.self] = newValue }
  }
}
