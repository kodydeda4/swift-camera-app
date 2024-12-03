import SwiftUI
import AVFoundation
import Photos
import AVFoundation
import Dependencies
import DependenciesMacros

@DependencyClient
struct UserPermissionsClient: Sendable {
  var status: @Sendable (PrivacyFeature) -> Status
  = { _ in reportIssue("\(Self.self).status"); return .undetermined }
  
  var request: @Sendable (PrivacyFeature) async -> Bool
  = { _ in reportIssue("\(Self.self).request"); return false }
  
  enum PrivacyFeature {
    case camera
    case microphone
    case photos
  }
  
  enum Status {
    case undetermined
    case authorized
    case denied
  }
}

extension UserPermissionsClient: DependencyKey {
  static var liveValue: UserPermissionsClient {
    return Self(
      status: { privacyFeature in
        switch privacyFeature {
          
        case .camera:
          switch AVCaptureDevice.authorizationStatus(for: .video) {
            
          case .notDetermined:
            return .undetermined
            
          case .authorized:
            return .authorized
            
          default:
            return .denied
          }
          
        case .microphone:
          switch AVAudioApplication.shared.recordPermission {
            
          case .undetermined:
            return .undetermined
            
          case .granted:
            return .authorized
            
          default:
            return .denied
          }
          
        case .photos:
          switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
            
          case .notDetermined:
            return .undetermined
            
          case .authorized:
            return .authorized
            
          default:
            return .denied
          }
        }
      },
      request: { privacyFeature in
        switch privacyFeature {
          
        case .camera:
          await AVCaptureDevice.requestAccess(for: .video)
          
        case .microphone:
          await AVAudioApplication.requestRecordPermission()
          
        case .photos:
          await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        }
      }
    )
  }
}

extension DependencyValues {
  var userPermissions: UserPermissionsClient {
    get { self[UserPermissionsClient.self] }
    set { self[UserPermissionsClient.self] = newValue }
  }
}
