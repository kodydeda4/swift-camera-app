import AVFoundation
import Dependencies
import DependenciesMacros
import Photos
import Sharing

@DependencyClient
struct UserPermissionsClient: Sendable {
  var status: @Sendable (Feature) -> Status
    = { _ in reportIssue("\(Self.self).status"); return .undetermined }
  var request: @Sendable (Feature) async -> Bool
    = { _ in reportIssue("\(Self.self).request"); return false }

  typealias State = [Feature:Status]
  
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
}

extension SharedReaderKey where Self == FileStorageKey<UserPermissionsClient.State>.Default {
  static var userPermissions: Self {
    Self[.fileStorage(.shared("userPermissions")), default: [:]]
  }
}

extension DependencyValues {
  var userPermissions: UserPermissionsClient {
    get { self[UserPermissionsClient.self] }
    set { self[UserPermissionsClient.self] = newValue }
  }
}

// MARK: - Implementation

extension UserPermissionsClient: DependencyKey {
  static var liveValue = Self(
    status: { 
      switch $0 {
      case .camera:
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .undetermined
        case .authorized: return .authorized
        default: return .denied
        }
      case .microphone:
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined: return .undetermined
        case .granted: return .authorized
        default: return .denied
        }
      case .photos:
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .notDetermined: return .undetermined
        case .authorized: return .authorized
        default: return .denied
        }
      }
    },
    request: {
      switch $0 {
      case .camera: await AVCaptureDevice.requestAccess(for: .video)
      case .microphone: await AVAudioApplication.requestRecordPermission()
      case .photos: await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
      }
    }
  )
}

extension UserPermissionsClient {
  static var previewValue = UserPermissionsClient(
    status: { _ in .undetermined },
    request: { _ in true }
  )
}

