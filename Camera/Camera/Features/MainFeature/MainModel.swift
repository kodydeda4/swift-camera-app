import SwiftUI
import SwiftUINavigation
import AVFoundation
import UIKit
import AVFoundation
import AsyncAlgorithms
import AVFoundation
import Photos

@Observable
@MainActor
final class MainModel: Identifiable {
  internal var isRecording = false
  internal var recordingDurationSeconds = 0
  internal let avCaptureSession = AVCaptureSession()
  internal var avCaptureDevice: AVCaptureDevice?
  internal var avCaptureDeviceInput: AVCaptureDeviceInput?
  internal var avCaptureMovieFileOutput = AVCaptureMovieFileOutput()
  internal let avVideoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
  internal let avVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  internal var recordingDelegate = MovieCaptureDelegate()
  internal var isVideoPermissionGranted: Bool { avVideoAuthorizationStatus == .authorized }
  
  func recordingButtonTapped() {
    !isRecording ? startRecording() : stopRecording()
  }
  
  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.handle(request: AVCaptureDevice.default(for: .video))
      }
      taskGroup.addTask {
        for await event in await self.recordingDelegate.events {
          await self.handle(event: event)
        }
      }
    }
  }
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable var model: MainModel
  
  var body: some View {
    NavigationStack {
      VStack {
        AVCaptureVideoPreviewLayerView(avVideoPreviewLayer: self.model.avVideoPreviewLayer)
      }
      .task { await self.model.task() }
      .overlay {
        Button(!self.model.isRecording ? "Start Recording" : "Stop Recording") {
          self.model.recordingButtonTapped()
        }
      }
    }
  }
}


// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
