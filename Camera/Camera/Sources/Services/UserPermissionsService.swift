import SwiftUI
import AVFoundation
import Photos
import AVFoundation

@Observable
class UserPermissionsService {
  
  private var camera = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
  private var microphone = AVAudioApplication.shared.recordPermission == .granted
  private var photoLibrary = PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized
  
  enum PrivacyFeature: CaseIterable {
    case camera
    case microphone
    case photoLibrary
    
    enum Status {
      case undetermined
      case authorized
      case denied
    }
  }

  init() {}
  
  // MARK: isAuthorized
  
  func isAuthorized(_ privacyFeatures: [PrivacyFeature]) -> Bool {
    privacyFeatures.allSatisfy(isAuthorized)
  }

  func isAuthorized(_ privacyFeature: PrivacyFeature) -> Bool {
    switch privacyFeature {
      
    case .camera:
      self.camera
      
    case .microphone:
      self.microphone
      
    case .photoLibrary:
      self.photoLibrary
    }
  }
  
  // MARK: request
  
  func request(_ privacyFeature: PrivacyFeature) async {
    switch privacyFeature {
      
    case .camera:
      self.camera = await AVCaptureDevice.requestAccess(for: .video)
      
    case .microphone:
      self.microphone = await AVAudioApplication.requestRecordPermission()
      
    case .photoLibrary:
      self.photoLibrary = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
    }
  }
  
  // MARK: status

  func isStatusDetermined(_ privacyFeature: PrivacyFeature) -> Bool {
    switch privacyFeature {
      
    case .camera:
      AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
      
    case .microphone:
      AVAudioApplication.shared.recordPermission == .undetermined
      
    case .photoLibrary:
      PHPhotoLibrary.authorizationStatus(for: .addOnly) == .notDetermined
    }
  }
}

