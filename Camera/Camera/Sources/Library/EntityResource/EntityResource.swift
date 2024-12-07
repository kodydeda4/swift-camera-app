import Foundation

enum EntityResource: String, CaseIterable {
  case coffee
  case guitar
  case pancakes
  case robot
}

extension EntityResource: Identifiable {
  var id: Self { self }
}

extension EntityResource: CustomStringConvertible {
  var description: String {
    rawValue.capitalized
  }
}
