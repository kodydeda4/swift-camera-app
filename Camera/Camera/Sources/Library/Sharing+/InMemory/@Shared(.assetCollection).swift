import IdentifiedCollections
import Photos
import Sharing
import UIKit

/// Referring to the Apple `Photos`app and `PhotosKit` API,
/// This object contains global shared state associated with the app's
/// asset collection and videos that are stored in the Photos app.
struct PhotosContext: Equatable {
  static let title = "KodysCameraApp"
  var assetCollection: PHAssetCollection?
  var videos: IdentifiedArrayOf<Video> = []
  
  struct Video: Identifiable, Equatable {
    var id: PHAsset { phAsset }
    let phAsset: PHAsset
    var avURLAsset: AVURLAsset
    var thumbnail: UIImage
  }
}

extension SharedReaderKey where Self == InMemoryKey<PhotosContext>.Default {
  static var photosContext: Self {
    Self[.inMemory("photosContext"), default: PhotosContext()]
  }
}
