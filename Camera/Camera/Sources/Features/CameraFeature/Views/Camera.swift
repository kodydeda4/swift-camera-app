import AVFoundation
import Sharing
import SwiftUI

extension CameraView {
  @MainActor internal var cameraPreview: some View {
    #if targetEnvironment(simulator)
      Image(.cameraPreview)
    #else
      CaptureVideoPreviewLayerView(
        captureVideoPreviewLayer: self.model.camera
          .captureVideoPreviewLayer
      )
      .ignoresSafeArea()
    #endif
  }
}

private struct CaptureVideoPreviewLayerView: UIViewControllerRepresentable {
  let captureVideoPreviewLayer: AVCaptureVideoPreviewLayer
  typealias UIViewControllerType = UIViewController

  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .black
    viewController.view.layer.addSublayer(captureVideoPreviewLayer)
    captureVideoPreviewLayer.frame = viewController.view.bounds
    return viewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    //...
  }
}

#Preview("Camera") {
  @Shared(.userPermissions) var userPermissions = .fullPermissions

  CameraView(model: CameraModel())
}

#Preview("Permissions Required") {
  @Shared(.userPermissions) var userPermissions = .denied

  CameraView(model: CameraModel())
}
