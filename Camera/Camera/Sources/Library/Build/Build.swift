import Foundation

struct Build {
  static var number: Number {
    (Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
      .flatMap(Int.init)
      .flatMap(Number.init)
      .unsafelyUnwrapped
  }

  struct Number: Equatable, Codable, CustomStringConvertible {
    var rawValue: Int

    var description: String {
      "v\(rawValue)"
    }
  }
}

