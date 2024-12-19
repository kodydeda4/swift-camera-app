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
  static var denied: UserPermissionsState = [
    .camera: .denied,
    .microphone: .denied,
    .photos: .denied,
  ]
  static var fullPermissions: UserPermissionsState = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
}

