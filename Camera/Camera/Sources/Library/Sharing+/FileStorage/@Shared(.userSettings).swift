import AVFoundation
import Sharing

struct UserSettings: Equatable, Codable {
  var torchMode = TorchMode.off
  var countdownTimer = 0
  var videoCaptureRecordingQuality = RecordingQuality.hd
  var videoZoomFactor: CGFloat = 1
  var cameraPosition = CameraPosition.front
  
  enum TorchMode {
    case on
    case off
    case auto
  }

  enum RecordingQuality {
    case hd
    case fourK
  }
  
  enum CameraPosition {
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

extension UserSettings.TorchMode:
  Identifiable, Equatable, Codable,
  CustomStringConvertible, CaseIterable
{
  
  var id: Self {
    self
  }
  
  var description: String {
    switch self {
    case .on:
      return "On"
    case .off:
      return "Off"
    case .auto:
      return "Auto"
    }
  }
  
  var rawValue: AVCaptureDevice.TorchMode {
    switch self {
    case .on:
      return .on
    case .off:
      return .off
    case .auto:
      return .auto
    }
  }
  
  init(_ rawValue: AVCaptureDevice.TorchMode) {
    switch rawValue {
    case .on:
      self = .on
    case .off:
      self = .off
    case .auto:
      self = .auto
    @unknown default:
      fatalError("????")
    }
  }
}

extension UserSettings.RecordingQuality:
  Identifiable, Equatable, Codable,
  CustomStringConvertible, CaseIterable
{
  
  var id: Self {
    self
  }
  
  var description: String {
    switch self {
    case .hd:
      return "HD"
    case .fourK:
      return "4k"
    }
  }
}

extension UserSettings.CameraPosition:
  Identifiable, Equatable, Codable,
  CustomStringConvertible, CaseIterable
{
  
  var id: Self {
    self
  }
  
  var description: String {
    switch self {
      
    case .front:
      return "Front"
      
    case .back:
      return "Back"
      
    case .unspecified:
      return "Unspecified"
    }
  }

  var rawValue: AVCaptureDevice.Position {
    switch self {
      
    case .unspecified:
      return .unspecified
      
    case .back:
      return .back
      
    case .front:
      return .front
    }
  }
  
  init(_ rawValue: AVCaptureDevice.Position) {
    switch rawValue {
      
    case .unspecified:
      self = .unspecified
      
    case .back:
      self = .back
      
    case .front:
      self = .front
     
    @unknown default:
      fatalError("????")
    }
  }
}

