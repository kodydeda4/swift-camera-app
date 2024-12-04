import Sharing
import Foundation

typealias UserPermissionsState = Dictionary<
  UserPermissionsClient.Feature,
  UserPermissionsClient.Status
>

extension SharedReaderKey where Self == FileStorageKey<UserPermissionsState>.Default {
  static var userPermissions: Self {
    Self[.fileStorage(.shared("userPermissions")), default: [:]]
  }
}

