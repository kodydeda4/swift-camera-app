import SwiftUI
import UIKit
import AVFoundation

extension MainView {
  @MainActor var camera: some View {
    Group {
//      if preview {
//        self.debug
//      } else {
        self.release
//      }
    }
  }
  
  @MainActor private var debug: some View {
    Image(.cameraPreview)
      .resizable()
      .scaledToFill()
  }
  
  @MainActor private var release: some View {
    AVCaptureVideoPreviewLayerView(
      avVideoPreviewLayer: self.model.avVideoPreviewLayer
    )
  }
}

fileprivate struct AVCaptureVideoPreviewLayerView: UIViewControllerRepresentable {
  let avVideoPreviewLayer: AVCaptureVideoPreviewLayer
  typealias UIViewControllerType = UIViewController
  
  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .black
    viewController.view.layer.addSublayer(avVideoPreviewLayer)
    avVideoPreviewLayer.frame = CGRect(
      x: 0,
      y: 0,
      width: UIScreen.main.bounds.size.width,
      height: UIScreen.main.bounds.size.height
    )
    avVideoPreviewLayer.videoGravity = .resizeAspectFill
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
