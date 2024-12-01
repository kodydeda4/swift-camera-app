import SwiftUI
import UIKit
import AVFoundation

internal struct AVCaptureVideoPreviewLayerView: UIViewControllerRepresentable {
  let avVideoPreviewLayer: AVCaptureVideoPreviewLayer
  typealias UIViewControllerType = UIViewController
  
  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .black
    viewController.view.layer.addSublayer(avVideoPreviewLayer)
    avVideoPreviewLayer.videoGravity = .resizeAspectFill
    avVideoPreviewLayer.frame = viewController.view.bounds
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    //...
  }
}


