import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class CaptureSessionModel {
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
  
  func task() async {
    Task.detached {
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask {
          await self.startCaptureSession(
            AVCaptureDevice.default(for: .video)
          )
        }
        // recording-delegate
        taskGroup.addTask {
          for await event in await self.recordingDelegate.events {
            await self.handleRecordingDelegateEvent(event)
          }
        }
      }
    }
  }

  func handleRecordingDelegateEvent(_ event: MovieCaptureDelegate.Event) {
    switch event {
      
    case let .fileOutput(
      output,
      didFinishRecordingTo: outputFileURL,
      from: connections,
      error: error
    ):
      print(output, outputFileURL, connections, error as Any)
      
      Task.detached {
        let isPhotoLibraryReadWriteAccessGranted: Bool = await {
          let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
          var isAuthorized = status == .authorized
          
          if status == .notDetermined {
            isAuthorized = await PHPhotoLibrary
              .requestAuthorization(for: .readWrite) == .authorized
          }
          return isAuthorized
        }()
        
        guard isPhotoLibraryReadWriteAccessGranted else {
          print("photo library read write access not granted.")
          return
        }
        
        try await PHPhotoLibrary.shared().performChanges {
          let creationRequest = PHAssetCreationRequest.forAsset()
          creationRequest.addResource(with: .video, fileURL: outputFileURL, options: nil)
        }
      }
    }
  }
  
  func startCaptureSession(_ value: AVCaptureDevice?) {
    self.avCaptureDevice = value
    
    guard let value else {
      print("❌ requestDefaultAVCaptureDeviceResponse is false")
      return
      //      return .none
    }
    
    self.avCaptureDeviceInput = try? AVCaptureDeviceInput(device: value)
    
    guard let input = self.avCaptureDeviceInput else {
      print("❌ avCaptureDeviceInput is nil")
      return
    }
    
    let output = self.avCaptureMovieFileOutput
    
    print("✅ input and output are non-nil")
    
    if self.avCaptureSession.canAddInput(input) {
      self.avCaptureSession.addInput(input)
      print("✅ added input")
    }
    if self.avCaptureSession.canAddOutput(output) {
      self.avCaptureSession.addOutput(output)
      print("✅ added output")
    }
    self.avVideoPreviewLayer.session = self.avCaptureSession
    
    avCaptureSession.startRunning()
    
    //      return .run { [avCaptureSession = state.avCaptureSession] _ in
    //        avCaptureSession.startRunning()
    //        print("✅ captureSession.startRunning()")
    //      }
  }
}

// MARK: - SwiftUI

struct CaptureSessionView: View {
  @Bindable public var store: CaptureSessionModel
  
  var body: some View {
    NavigationStack {
      AVCaptureVideoPreviewLayerView(avVideoPreviewLayer: store.avVideoPreviewLayer)
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .overlay(content: self.overlay)
    .task { await self.store.task() }
  }
}

extension CaptureSessionView {
  @MainActor internal func overlay() -> some View {
    VStack {
      Spacer()
      self.debugView
      self.footer
    }
  }
  
  @MainActor private var footer: some View {
    HStack {
      Button(store.isRecording ? "Start Recording" : "Stop Recording") {
        //        send(.recordingButtonTapped)
      }
      Button("End Session") {
        //        send(.endSessionButtonTapped)
      }
    }
    .buttonStyle(.borderedProminent)
  }
  
  @MainActor private var debugView: some View {
    GroupBox {
      VStack(alignment: .leading) {
        debugLine("isPermissionGranted", store.isVideoPermissionGranted.description)
        debugLine("isCaptureSessionRunning", store.avCaptureSession.isRunning.description)
        debugLine("isRecording", store.isRecording.description)
      }
    }
    .padding()
  }
  
  @MainActor private func debugLine(_ title: String, _ description: String) -> some View {
    HStack {
      Text("\(title):")
        .bold()
      Text(description)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - SwiftUI Previews

//#Preview {
//  CaptureSessionView(store: Store(initialState: CaptureSession.State()) {
//    CaptureSession()
//  })
//}
