import Sharing
import AVFoundation

struct UserSettings: Equatable, Codable {
  var isFlashEnabled = false
  var videoCaptureCountdownTimerDuration: CGFloat = 0
  var videoCaptureRecordingQuality = RecordingQuality.hd
  var videoZoomFactor: CGFloat = 1
  var cameraPosition = CameraPosition.front
  
  enum RecordingQuality:
    Identifiable, Equatable, Codable,
    CustomStringConvertible, CaseIterable
  {
    case hd
    case fourK
    
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
  
  enum CameraPosition: Equatable, Codable {
    case front
    case back
    case unspecified
    
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
}

extension SharedReaderKey where Self == FileStorageKey<UserSettings>.Default {
  static var userSettings: Self {
    Self[.fileStorage(.shared("userSettings")), default: UserSettings()]
  }
}
