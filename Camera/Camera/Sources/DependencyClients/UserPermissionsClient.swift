import SwiftUI
import AVFoundation
import Photos
import AVFoundation
import Dependencies
import DependenciesMacros

@DependencyClient
struct UserPermissionsClient: Sendable {
  var status: @Sendable (Feature) -> Status = { _ in .undetermined }
  var request: @Sendable (Feature) async -> Bool = { _ in false }
  
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

extension DependencyValues {
  var userPermissions: UserPermissionsClient {
    get { self[UserPermissionsClient.self] }
    set { self[UserPermissionsClient.self] = newValue }
  }
}
