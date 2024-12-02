import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class CaptureSessionModel {
  var isRecording = false
  var recordingDurationSeconds = 0
  let avCaptureSession = AVCaptureSession()
  var avCaptureDevice: AVCaptureDevice?
  var avCaptureDeviceInput: AVCaptureDeviceInput?
  var avCaptureMovieFileOutput = AVCaptureMovieFileOutput()
  let avVideoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
  let avVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  var recordingDelegate = MovieCaptureDelegate()
  var isVideoPermissionGranted: Bool { avVideoAuthorizationStatus == .authorized }
  var destination: Destination?
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
    case arObjectPicker(ARObjectPickerModel)
  }
  
  func task() async {
    Task.detached {
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask {
          await self.startCaptureSession(with: .default(for: .video))
        }
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
      
      Task {
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
  
  func startCaptureSession(with device: AVCaptureDevice?) {
    self.avCaptureDevice = device
    
    guard let device else {
      print("❌ requestDefaultAVCaptureDeviceResponse is false")
      return
    }
    
    self.avCaptureDeviceInput = try? AVCaptureDeviceInput(device: device)
    
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
    
    Task.detached {
      await self.avCaptureSession.startRunning()
    }
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
