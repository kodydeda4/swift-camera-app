import SwiftUI
import UIKit
import AVFoundation
import RealityKit
import ARKit
import Photos

extension MainView {
  @MainActor var camera: some View {
    ContentView()
  }
}

// @DEDA 👨🏼‍🍳🤖🤔🤔🤔🤔🤔🤔🤔🤔🤔🤔🤔🤔🤔🤔🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤🤤

struct ContentView: View {
  @State private var isRecording = false
  @State private var recorder: ARVideoRecorder?
  
  var body: some View {
    ZStack {
      ARViewContainer(isRecording: $isRecording, recorder: $recorder)
        .edgesIgnoringSafeArea(.all)
      
      VStack {
        Spacer()
        Button(action: {
          if isRecording {
            recorder?.stopRecording { url in
              saveVideoToPhotos(url: url)
            }
          } else {
            recorder?.startRecording()
          }
          isRecording.toggle()
        }) {
          Text(isRecording ? "Stop Recording" : "Start Recording")
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
      }
    }
  }
}

struct ARViewContainer: UIViewRepresentable {
  @Binding var isRecording: Bool
  @Binding var recorder: ARVideoRecorder?
  
  func makeUIView(context: Context) -> ARView {
    let arView = ARView(frame: .zero)
    recorder = ARVideoRecorder(arView: arView)
    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal, .vertical]
    config.environmentTexturing = .automatic
    arView.session.run(config)
    return arView
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {
    // Load the coffee model and anchor it in the real world.
    let anchorEntity = AnchorEntity(plane: .any)
    
    guard let modelEntity = try? Entity.loadModel(named: "coffee")
    else { return }
    
    anchorEntity.addChild(modelEntity)
    
    uiView.scene.addAnchor(anchorEntity)
  }
}

class ARVideoRecorder {
  private let arView: ARView
  private var assetWriter: AVAssetWriter?
  private var assetWriterInput: AVAssetWriterInput?
  private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
  private var displayLink: CADisplayLink?
  private var recordingStartTime: CFTimeInterval?
  
  init(arView: ARView) {
    self.arView = arView
  }
  
  func startRecording() {
    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
    setupAssetWriter(outputURL: outputURL)
    
    recordingStartTime = CACurrentMediaTime()
    displayLink = CADisplayLink(target: self, selector: #selector(recordFrame))
    displayLink?.add(to: .main, forMode: .default)
  }
  
  func stopRecording(completion: @escaping (URL) -> Void) {
    displayLink?.invalidate()
    assetWriterInput?.markAsFinished()
    assetWriter?.finishWriting {
      if let url = self.assetWriter?.outputURL {
        DispatchQueue.main.async {
          completion(url)
        }
      }
    }
  }
  
  @objc private func recordFrame() {
    guard
      let assetWriter = assetWriter,
      let assetWriterInput = assetWriterInput,
      assetWriter.status == .writing,
      let pixelBufferAdaptor = pixelBufferAdaptor,
      assetWriterInput.isReadyForMoreMediaData
    else { return }
    
    let currentTime = CACurrentMediaTime()
    let elapsedTime = currentTime - (recordingStartTime ?? currentTime)
    
    //    let pixelBuffer = arView.snapshot().cgImage?.toPixelBuffer()
    arView.snapshot(saveToHDR: false) { image in
      let pixelBuffer = image?.cgImage?.toPixelBuffer()
      
      if let pixelBuffer  {
        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: CMTime(seconds: elapsedTime, preferredTimescale: 600))
      }
    }
  }
  
  private func setupAssetWriter(outputURL: URL) {
    // Get the device screen dimensions
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let scale = UIScreen.main.scale // To account for retina scaling
    let videoWidth = Int(screenWidth * scale)
    let videoHeight = Int(screenHeight * scale)
    
    assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    
    // @DEDA you can probaly grab ur device res here.
    // Define video settings for high quality
    // Initialize the AVAssetWriter with the desired output URL and file type
    
    // Define video settings with dynamic resolution
    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: NSNumber(value: videoWidth),
      AVVideoHeightKey: NSNumber(value: videoHeight),
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: NSNumber(value: 10_000_000), // Higher bitrate for better quality
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        AVVideoMaxKeyFrameIntervalKey: NSNumber(value: 30) // Keyframe every 30 frames
      ]
    ]
    
    // Create an AVAssetWriterInput with the settings
    assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    assetWriterInput?.expectsMediaDataInRealTime = true
    
    // Configure the pixel buffer adaptor with dynamic dimensions
    pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: assetWriterInput!,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: NSNumber(value: videoWidth),
        kCVPixelBufferHeightKey as String: NSNumber(value: videoHeight)
      ]
    )
    
    if let assetWriter = assetWriter, let assetWriterInput = assetWriterInput {
      assetWriter.add(assetWriterInput)
      assetWriter.startWriting()
      assetWriter.startSession(atSourceTime: .zero)
    }
  }
}

extension CGImage {
  func toPixelBuffer() -> CVPixelBuffer? {
    let width = self.width
    let height = self.height
    var pixelBuffer: CVPixelBuffer?
    
    let attrs = [
      kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
      kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
    ] as CFDictionary
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    guard let buffer = pixelBuffer else { return nil }
    
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let context = CGContext(
      data: pixelData,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    )
    
    context?.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    
    return buffer
  }
}

func saveVideoToPhotos(url: URL) {
  PHPhotoLibrary.requestAuthorization { status in
    if status == .authorized {
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      }) { success, error in
        if success {
          print("Video saved to Photos!")
        } else {
          print("Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
        }
      }
    }
  }
}
