import Foundation

struct AnyError: Error, Equatable {
  var rawValue: String
  
  init(_ string: String) {
    self.rawValue = string
  }
}
