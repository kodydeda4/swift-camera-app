import SwiftUI
import SwiftUINavigation
import AVFoundation
import UIKit
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
  
  internal func stopRecording() {
    avCaptureMovieFileOutput.stopRecording()
    isRecording = false
    // state.delegate = .none
    print("✅ stopped recording")
    // state.isRecording = false
    return
  }
  
  internal func startRecording() {
    let movieOutput = self.avCaptureMovieFileOutput
    
    guard !self.avCaptureMovieFileOutput.isRecording else {
      return self.stopRecording()
    }
    
    guard let connection = movieOutput.connection(with: .video) else {
      print("❌ Configuration error. No video connection found")
      return
    }
    
    // Configure connection for HEVC capture.
    if movieOutput.availableVideoCodecTypes.contains(.hevc) {
      movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
    }
    
    // Enable video stabilization if the connection supports it.
    if connection.isVideoStabilizationSupported {
      connection.preferredVideoStabilizationMode = .auto
    }
    
    // Start a timer to update the recording time.
    // ...
    
    //@DEDA
    movieOutput.startRecording(
      to: URL.movieFileOutput(id: UUID()),
      recordingDelegate: recordingDelegate
    )
    isRecording = true
    print("✅ started recording")
    return
  }
  
  internal func handle(event: MovieCaptureDelegate.Event) {
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
  
  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await AVCaptureDevice.requestAccess(for: .video)
        AVCaptureDevice.default(for: .video)
      }
      taskGroup.addTask {
        for await event in await self.recordingDelegate.events {
          await self.handle(event: event)
        }
      }
    }
  }
}

// @DEDA idk rename it to mirror the protocol
public final class MovieCaptureDelegate: NSObject {
  public let events = AsyncChannel<Event>()
  
  public enum Event {
    case fileOutput(
      _ output: AVCaptureFileOutput,
      didFinishRecordingTo: URL,
      from: [AVCaptureConnection],
      error: Error?
    )
  }
}

// MARK: - Computed Properties

extension MovieCaptureDelegate: AVCaptureFileOutputRecordingDelegate {
  public func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    Task {
      await events.send(.fileOutput(
        output,
        didFinishRecordingTo: outputFileURL,
        from: connections,
        error: error
      ))
    }
  }
}


extension URL {
  /// A unique output location to write a movie.
  internal static func movieFileOutput(id: UUID) -> URL {
    URL.temporaryDirectory
      .appending(component: id.uuidString)
      .appendingPathExtension(for: .quickTimeMovie)
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

// MARK: - Private

private struct AVCaptureVideoPreviewLayerView: UIViewControllerRepresentable {
  let avVideoPreviewLayer: AVCaptureVideoPreviewLayer
  typealias UIViewControllerType = UIViewController
  
  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .black
    viewController.view.layer.addSublayer(avVideoPreviewLayer)
    avVideoPreviewLayer.frame = viewController.view.bounds
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    //...
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
