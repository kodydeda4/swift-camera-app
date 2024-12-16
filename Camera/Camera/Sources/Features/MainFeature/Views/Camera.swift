import SwiftUI
import Sharing
import AVFoundation

extension MainView {
  @MainActor internal var camera: some View {
    AVCaptureVideoPreviewLayerView(avVideoPreviewLayer: self.model.avVideoPreviewLayer)
  }
}

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
