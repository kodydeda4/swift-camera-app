import AsyncAlgorithms
import AVFoundation
import Dependencies
import DependenciesMacros
import Photos
import SwiftUI
import SwiftUINavigation

extension CameraClient {
  static var previewValue: Self {

    return Self(
      requestAccess: { mediaType in
        await AVCaptureDevice.requestAccess(for: mediaType)
      },
      authorizationStatus: { mediaType in
        AVCaptureDevice.authorizationStatus(for: mediaType)
      },
      connect: { _ in },
      startRecording: { _ in },
      stopRecording: {},
      adjust: { _ in },
      events: { .init() }
    )
  }
}
