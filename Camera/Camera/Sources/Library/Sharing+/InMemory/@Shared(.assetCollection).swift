import Photos
import Sharing

extension SharedReaderKey where Self == InMemoryKey<PHAssetCollection?>.Default {
  static var assetCollection: Self {
    Self[.inMemory("assetCollection"), default: .none]
  }
}
