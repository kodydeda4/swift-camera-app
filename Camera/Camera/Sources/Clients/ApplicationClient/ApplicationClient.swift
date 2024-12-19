import Dependencies
import DependenciesMacros
import SwiftUI

@DependencyClient
struct ApplicationClient: Sendable {
  var openSettings: @Sendable () async throws -> Void

  struct Failure: Error, Equatable {
    let rawValue: String
  }
}

extension DependencyValues {
  var application: ApplicationClient {
    get { self[ApplicationClient.self] }
    set { self[ApplicationClient.self] = newValue }
  }
}

extension ApplicationClient: DependencyKey {
  static var liveValue = Self {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      throw Failure(rawValue: "UIApplication.openSettingsURLString")
    }
    guard UIApplication.shared.canOpenURL(url) else {
      throw Failure(rawValue: "UIApplication.shared.canOpenURL")
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}
