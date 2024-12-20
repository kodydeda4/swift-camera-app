import Photos
import Foundation

extension PhotoLibraryClient.FetchRequest.AssetCollection {
  init(title: String) {
    self = Self(
      type: .album,
      subtype: .any,
      options: .make {
        $0.predicate = NSPredicate(format: "title = %@", title)
      }
    )
  }
}

extension PhotoLibraryClient.FetchRequest.Assets {
  static func videos(in collection: PHAssetCollection) -> Self {
    Self(
      collection: collection,
      options: .make {
        $0.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        $0.predicate = NSPredicate(
          format: "mediaType == %d",
          PHAssetMediaType.video.rawValue
        )
      }
    )
  }
}

extension PhotoLibraryClient.FetchRequest.Thumbnail {
  static func highQuality(asset: PHAsset) -> Self {
    Self(asset: asset, options: .highQuality())
  }
}



// MARK: Private

fileprivate extension PHFetchOptions {
  static func make(
    with mutations: (PHFetchOptions) -> Void
  ) -> PHFetchOptions {
    let rv = Self()
    mutations(rv)
    return rv
  }
}

fileprivate extension PHVideoRequestOptions {
  static func highQuality() -> PHVideoRequestOptions {
    let rv = PHVideoRequestOptions()
    rv.deliveryMode = .highQualityFormat
    rv.isNetworkAccessAllowed = true
    return rv
  }
}
