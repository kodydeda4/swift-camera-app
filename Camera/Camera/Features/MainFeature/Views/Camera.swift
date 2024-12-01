import SwiftUI
import UIKit
import AVFoundation

// @DEDA
// idk why it's not working =(
// maybe something happened between this and tca ???
// maybe somewhere between .task() and captureSession.startRunning() ?...
//
// This guy has a video with example code.
// https://www.neuralception.com/detection-app-tutorial-camera-feed/

internal struct AVCaptureVideoPreviewLayerView: UIViewControllerRepresentable {
  let avVideoPreviewLayer: AVCaptureVideoPreviewLayer
  typealias UIViewControllerType = UIViewController
  
  func makeUIViewController(context: Context) -> UIViewController {
    let viewController = UIViewController()
    viewController.view.backgroundColor = .black
    viewController.view.layer.addSublayer(avVideoPreviewLayer)
    avVideoPreviewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
    avVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
//    avVideoPreviewLayer.frame = viewController.view.bounds
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    //...
  }
}


