import Photos

extension MainModel {
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
}
