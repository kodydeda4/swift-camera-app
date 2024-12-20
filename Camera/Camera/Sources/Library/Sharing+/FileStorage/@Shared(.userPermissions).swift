import Sharing

typealias UserPermissionsState = Dictionary<
  UserPermissionsClient.Feature,
  UserPermissionsClient.Status
>

extension SharedReaderKey where Self == FileStorageKey<UserPermissionsState>.Default {
  static var userPermissions: Self {
    Self[.fileStorage(.shared("userPermissions")), default: [:]]
  }
}

// MARK: - SwiftUI Previews

extension UserPermissionsState {
  static var authorized: UserPermissionsState = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  static var denied: UserPermissionsState = [
    .camera: .denied,
    .microphone: .denied,
    .photos: .denied,
  ]
}

