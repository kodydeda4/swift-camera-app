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
    avVideoPreviewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
    avVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


