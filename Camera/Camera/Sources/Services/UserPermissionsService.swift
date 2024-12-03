import SwiftUI
import AVFoundation
import Photos
import AVFoundation

protocol UserPermissionsServiceProtocol {
  var camera: Bool { get }
  var microphone: Bool { get }
  var photos: Bool { get }
  
  var statusCamera: AVAuthorizationStatus { get }
  var statusMicrophone: AVAudioApplication.recordPermission { get }
  var statusPhotos: PHAuthorizationStatus { get }
  
  func requestCamera() async
  func requestMicrophone() async
  func requestPhotos() async
}

// MARK: - Live

@Observable
final class UserPermissionsService: UserPermissionsServiceProtocol {
  var camera = false
  var microphone = false
  var photos = false

  init() {
    self.refresh()
  }
  
  private func refresh() {
    self.camera = statusCamera == .authorized
    self.microphone = statusMicrophone == .granted
    self.photos = statusPhotos == .authorized
  }
  
  var statusCamera: AVAuthorizationStatus {
    AVCaptureDevice.authorizationStatus(for: .video)
  }
  var statusMicrophone: AVAudioApplication.recordPermission {
    AVAudioApplication.shared.recordPermission
  }
  var statusPhotos: PHAuthorizationStatus {
    PHPhotoLibrary.authorizationStatus(for: .addOnly)
  }
  func requestCamera() async {
    self.camera = await AVCaptureDevice.requestAccess(for: .video)
  }
  func requestMicrophone() async {
    self.microphone = await AVAudioApplication.requestRecordPermission()
  }
  func requestPhotos() async {
    self.photos = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
  }
}

//// MARK: - Preview
//
//@Observable
//final class UserPermissionsServicePreview: UserPermissionsServiceProtocol {
//  var camera: AVAuthorizationStatus { .authorized }
//  var microphone: AVAudioApplication.recordPermission { .granted }
//  var photos: PHAuthorizationStatus { .authorized }
//  
//  func requestCamera() async -> Bool { true }
//  func requestMicrophone() async -> Bool { true }
//  func requestPhotos() async -> Bool { true }
//}
