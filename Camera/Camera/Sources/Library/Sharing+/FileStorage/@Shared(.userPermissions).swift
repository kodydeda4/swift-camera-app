import Sharing

struct UserPermissions {
  
  enum Feature: Codable, CaseIterable {
    case camera
    case microphone
    case photos
  }
  
  enum Status: Codable {
    case undetermined
    case authorized
    case denied
  }
  
  typealias State = Dictionary<Feature, Status>
}

extension SharedReaderKey where Self == FileStorageKey<UserPermissions.State>.Default {
  static var userPermissions: Self {
    Self[.fileStorage(.shared("userPermissions")), default: [:]]
  }
}

// MARK: - SwiftUI Previews

extension UserPermissions.State {
  static var authorized: Self = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  static var denied: Self = [
    .camera: .denied,
    .microphone: .denied,
    .photos: .denied,
  ]
}

