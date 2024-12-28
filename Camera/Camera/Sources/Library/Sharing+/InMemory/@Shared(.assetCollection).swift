import Photos
import Sharing
import IdentifiedCollections
import UIKit

struct Video: Identifiable {
  var id: PHAsset { phAsset }
  let phAsset: PHAsset
  var avURLAsset: AVURLAsset?
  var thumbnail: UIImage?
}

extension SharedReaderKey where Self == InMemoryKey<PHAssetCollection?>.Default {
  static var assetCollection: Self {
    Self[.inMemory("assetCollection"), default: .none]
  }
}

extension SharedReaderKey where Self == InMemoryKey<IdentifiedArrayOf<Video>>.Default {
  static var videos: Self {
    Self[.inMemory("videos"), default: []]
  }
}
