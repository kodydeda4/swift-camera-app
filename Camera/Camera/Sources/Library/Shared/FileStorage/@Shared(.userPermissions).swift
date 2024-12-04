import Sharing
import Foundation

extension SharedReaderKey where Self == FileStorageKey<UserPermissionsState>.Default {
  static var userPermissions: Self {
    Self[.fileStorage(.shared("userPermissions")), default: [:]]
  }
}

fileprivate typealias UserPermissionsState = Dictionary<
  UserPermissionsClient.Feature,
  UserPermissionsClient.Status
>
