import Sharing
import Foundation

struct UserPermissionsState: Codable {
  var camera = false
  var microphone = false
  var photos = false
}

extension SharedReaderKey where Self == InMemoryKey<UserPermissionsState>.Default {
  static var userPermissions: Self {
    Self[.inMemory("userPermissions"), default: UserPermissionsState()]
  }
}
