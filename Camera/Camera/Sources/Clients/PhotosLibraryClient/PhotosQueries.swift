import Photos

// MARK: PhotoLibraryChange

extension PhotosLibraryClient.Request.PhotoLibraryChange {
  static func save(
    contentsOf url: URL,
    to photosContext: PHAssetCollection
  ) -> Self {
    Self {
      let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      
      if let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset {
        let albumChangeRequest = PHAssetCollectionChangeRequest(for: photosContext)
        albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
      }
    }
  }
  
  static func delete(assets: [PHAsset]) -> Self {
    Self {
      PHAssetChangeRequest.deleteAssets(assets as NSArray)
    }
  }
  
  static func createAssetCollection(withTitle title: String) -> Self {
    Self {
      PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
    }
  }
}

// MARK: AssetCollections

extension PhotosLibraryClient.Request.AssetCollections {
  static func albums(with title: String) -> Self {
    Self(type: .album, subtype: .any, options: .make {
      $0.predicate = NSPredicate(format: "title = %@", title)
    })
  }
}

// MARK: Assets

extension PhotosLibraryClient.Request.Assets {
  static func videos(in collection: PHAssetCollection) -> Self {
    Self(collection: collection, options: .make {
      $0.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      $0.predicate = NSPredicate(
        format: "mediaType == %d",
        PHAssetMediaType.video.rawValue
      )
    })
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

