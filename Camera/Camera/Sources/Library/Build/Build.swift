import Foundation

struct Build {
  static var version: Version {
    (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
      .flatMap(Double.init)
      .flatMap(Version.init)
      .unsafelyUnwrapped
  }

  struct Version: Equatable, Codable, CustomStringConvertible {
    var rawValue: Double

    var description: String {
      "v\(rawValue)"
    }
  }
}

