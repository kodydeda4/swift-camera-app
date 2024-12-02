import SwiftUI

struct ApplicationClient {
  var openSettings: () throws -> Void
}

extension ApplicationClient {
  static var liveValue = Self {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      throw AnyError("UIApplication.openSettingsURLString is nil.")
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}
