import SwiftUI
import AVFoundation
import Photos
import AVFoundation

protocol UserPermissionsServiceProtocol {
  var camera: AVAuthorizationStatus { get }
  var microphone: AVAudioApplication.recordPermission { get }
  var photos: PHAuthorizationStatus { get }
  
  func cameraRequest() async -> Bool
  func microphoneRequest() async -> Bool
  func photosRequest() async -> Bool
}

// MARK: - Live

@Observable
final class UserPermissionsService: UserPermissionsServiceProtocol {
  var camera: AVAuthorizationStatus {
    AVCaptureDevice.authorizationStatus(for: .video)
  }
  var microphone: AVAudioApplication.recordPermission {
    AVAudioApplication.shared.recordPermission
  }
  var photos: PHAuthorizationStatus {
    PHPhotoLibrary.authorizationStatus(for: .addOnly)
  }
  
  func cameraRequest() async -> Bool {
    await AVCaptureDevice.requestAccess(for: .video)
  }
  func microphoneRequest() async -> Bool {
    await AVAudioApplication.requestRecordPermission()
  }
  func photosRequest() async -> Bool {
    await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
  }
}

// MARK: - Preview

@Observable
final class UserPermissionsServicePreview: UserPermissionsServiceProtocol {
  var camera: AVAuthorizationStatus { .authorized }
  var microphone: AVAudioApplication.recordPermission { .granted }
  var photos: PHAuthorizationStatus { .authorized }
  
  func cameraRequest() async -> Bool { true }
  func microphoneRequest() async -> Bool { true }
  func photosRequest() async -> Bool { true }
}
