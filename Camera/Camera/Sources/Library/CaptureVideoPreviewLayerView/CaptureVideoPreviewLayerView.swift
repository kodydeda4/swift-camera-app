import AVFoundation
import SwiftUI

struct CaptureVideoPreviewLayerView: View {
  let captureVideoPreviewLayer: AVCaptureVideoPreviewLayer

  var body: some View {
    #if targetEnvironment(simulator)
      PreviewValue()
    #else
    LiveValue(captureVideoPreviewLayer: captureVideoPreviewLayer)
      .clipped()
    #endif
  }
}

// MARK: - LiveValue

/// UIKit view that actually displays the `AVCaptureVideoPreviewLayer` when the device is running.
fileprivate struct LiveValue: UIViewControllerRepresentable {
  let captureVideoPreviewLayer: AVCaptureVideoPreviewLayer

  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .black
    viewController.view.layer.addSublayer(captureVideoPreviewLayer)
    captureVideoPreviewLayer.frame = viewController.view.bounds
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    
    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    //...
  }
}

// MARK: - PreviewValue

/// Attempts to mirror what the `CaptureVideoPreviewLayerView` looks like on a real device,
/// but with a static image instead. The borders and frame are hardcoded.
fileprivate struct PreviewValue: View {
  var body: some View {
    VStack {}
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay {
        Image(.cameraPreview)
          .resizable()
          .scaledToFill()
          .ignoresSafeArea()
      }
      .overlay {
        VStack {
          Color.black
            .frame(height: 100)
          Spacer()
          Color.black
            .frame(height: 70)
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
  }
}

