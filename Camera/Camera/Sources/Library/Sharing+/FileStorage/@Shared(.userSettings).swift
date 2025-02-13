import AVFoundation
import Sharing

struct UserSettings: Equatable, Codable {
  var camera = Camera.back
  var zoom: CGFloat = 1
  var countdownTimer = 3
  var torchMode = TorchMode.off

  enum TorchMode: Equatable, Codable, CaseIterable {
    case on
    case off
    case auto
  }
  
  enum Camera: Equatable, Codable, CaseIterable {
    case front
    case back
    case unspecified
  }
}

extension SharedReaderKey where Self == FileStorageKey<UserSettings>.Default {
  static var userSettings: Self {
    Self[.fileStorage(.shared("userSettings")), default: UserSettings()]
  }
}

// MARK: - Extensions

extension UserSettings.TorchMode: Identifiable, CustomStringConvertible {
  
  var id: Self { self }
  
  var description: String {
    switch self {
    case .on: return "On"
    case .off: return "Off"
    case .auto: return "Auto"
    }
  }
  
  var rawValue: AVCaptureDevice.TorchMode {
    switch self {
    case .on: return .on
    case .off: return .off
    case .auto: return .auto
    }
  }
  
  init(_ rawValue: AVCaptureDevice.TorchMode) {
    self = {
      switch rawValue {
      case .on: return .on
      case .off: return .off
      case .auto: return .auto
      @unknown default: fatalError("????")
      }
    }()
  }
}

extension UserSettings.Camera: Identifiable, CustomStringConvertible {
  
  var id: Self { self }
  
  var description: String {
    switch self {
    case .front: return "Front"
    case .back: return "Back"
    case .unspecified: return "Unspecified"
    }
  }
  
  var rawValue: AVCaptureDevice.Position {
    switch self {
    case .unspecified: return .unspecified
    case .back: return .back
    case .front: return .front
    }
  }
  
  init(_ rawValue: AVCaptureDevice.Position) {
    self = {
      switch rawValue {
      case .unspecified: return .unspecified
      case .back: return .back
      case .front: return .front
      @unknown default: fatalError("????")
      }
    }()
  }
}

