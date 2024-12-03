import AsyncAlgorithms
import AVFoundation
import PhotosUI
import SwiftUI
import Photos
import SwiftUINavigation
import Sharing
import Dependencies
import RealityKit
import ARKit

// MARK: Internal
// @DEDA
// Once you get this working at a decent speed,
// you can create an interface.

// Problems:
// 1. Laggy AF
// 2. After exporting the first video, other videos won't export.
// 3. Coffee cup gets rendered multiple times (i think after you record it generates a new one or smthn)
// 4. Video quality?

struct ARVideoRecorderClient {
  var startRecording: () -> Void
  var stopRecording: () -> Void//VideoURL
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
    
    Task.detached {
      await self.arView.snapshot(saveToHDR: false) { image in
        guard let pixelBuffer = image?.cgImage?.toPixelBuffer() else { return }
        pixelBufferAdaptor.append(
          pixelBuffer,
          withPresentationTime: CMTime(seconds: elapsedTime, preferredTimescale: 600)
        )
      }
    }
  }
  
  private func setupAssetWriter(outputURL: URL) {
    // Get the device screen dimensions
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    let scale = UIScreen.main.scale // To account for retina scaling
    let videoWidth = Int(screenWidth * scale * 0.25)
    let videoHeight = Int(screenHeight * scale * 0.25)
    
    assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    
    // Define video settings with dynamic resolution
    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: NSNumber(value: videoWidth),
      AVVideoHeightKey: NSNumber(value: videoHeight),
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: NSNumber(value: 5_000_000), // Reduce bitrate for faster encoding
        AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel, // Use a simpler profile
        AVVideoMaxKeyFrameIntervalKey: NSNumber(value: 15) // More frequent keyframes
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

struct ARViewContainer: UIViewRepresentable {
  @Bindable var model: MainModel
  
  func makeUIView(context: Context) -> ARView {
    let arView = ARView(frame: .zero)
    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal, .vertical]
    config.environmentTexturing = .automatic
    arView.session.run(config)
    self.model.recorder = ARVideoRecorder(arView: arView)
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

