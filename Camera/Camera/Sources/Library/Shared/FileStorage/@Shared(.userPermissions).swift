import Sharing
import Foundation

struct UserPermissionsState: Codable {
  var camera = false
  var microphone = false
  var photos = false
}

extension SharedReaderKey where Self == FileStorageKey<UserPermissionsState>.Default {
  static var userPermissions: Self {
    Self[.fileStorage(.shared("userPermissions")), default: UserPermissionsState()]
  }
}

