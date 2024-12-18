import AVFoundation
import Sharing
import SwiftUI

extension MainView {
  @MainActor internal var camera: some View {
    //@DEDA plz fix
    Group {
//      if true {
//        Image(.cameraPreview)
      CaptureVideoPreviewLayerView(captureVideoPreviewLayer: self.model.camera.captureVideoPreviewLayer)
//      } else {
//        CaptureVideoPreviewLayerView(captureVideoPreviewLayer: self.model.captureVideoPreviewLayer)
      
      //      }
    }
    .ignoresSafeArea()
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

#Preview("Happy path") {
  let value: Dictionary<
    UserPermissionsClient.Feature,
    UserPermissionsClient.Status
  > = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value

  MainView(model: MainModel())
}
