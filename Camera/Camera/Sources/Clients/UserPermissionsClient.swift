import SwiftUI
import AVFoundation
import Photos
import AVFoundation

///  Request access to `PrivacyFeatures` or get their `AuthorizationStatus`.
struct UserPermissionsClient {
  var hasUserPermissions: @Sendable () -> Bool
  var request: @Sendable (PrivacyFeature) async -> Void
  var status: @Sendable (PrivacyFeature) -> AuthorizationStatus
  
  enum PrivacyFeature {
    case camera
    case microphone
    case photoLibrary
  }
  
  enum AuthorizationStatus {
    case undetermined
    case authorized
    case denied
  }
}

// MARK: - Implementation

extension UserPermissionsClient {
  static var liveValue: Self {
    let service = Service()
    
    return Self(
      hasUserPermissions: { service.hasUserPermissions },
      request: { await service.request(privacyFeature: $0) },
      status: { service.status(of: $0) }
    )
  }
  
  private final class Service {
    private var camera = status(of: .camera)
    private var microphone = status(of: .microphone)
    private var photoLibrary = status(of: .photoLibrary)
    
    var hasUserPermissions: Bool {
      [camera, microphone, photoLibrary].allSatisfy { $0 == .authorized }
    }
    
    func request(privacyFeature: PrivacyFeature) async {
      switch privacyFeature {
        
      case .camera:
        self.camera = await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        
      case .microphone:
        self.microphone = await AVAudioApplication.requestRecordPermission() ? .authorized : .denied
        
      case .photoLibrary:
        self.photoLibrary = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized ? .authorized : .denied
      }
    }
    
    func status(of privacyFeature: PrivacyFeature) -> AuthorizationStatus {
      Self.status(of: privacyFeature)
    }
    
    private static func status(of privacyFeature: PrivacyFeature) -> AuthorizationStatus {
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
        
      case .photoLibrary:
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
          
        case .notDetermined:
          return .undetermined
          
        case .authorized:
          return .authorized
          
        default:
          return .denied
        }
      }
    }
  }
}

