import IdentifiedCollections
import Photos
import Sharing
import UIKit

/// Photos, referring to the name of the Apple photos app and photos album.
struct PhotosContext {
  static let title = "KodysCameraApp"
  var assetCollection: PHAssetCollection?
  var videos: IdentifiedArrayOf<Video> = []
  
  struct Video: Identifiable {
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
