import Dependencies
import DependenciesMacros
import Photos
import Combine

@DependencyClient
struct PhotoLibraryClient: Sendable {
  var fetch: (String) async throws -> PHAssetCollection
  var create: (String) async throws -> PHAssetCollection
  var save: (URL, PHAssetCollection) async throws -> Void
}

extension DependencyValues {
  var photoLibrary: PhotoLibraryClient {
    get { self[PhotoLibraryClient.self] }
    set { self[PhotoLibraryClient.self] = newValue }
  }
}

extension PhotoLibraryClient: DependencyKey {
  static var liveValue = Self(
    fetch: { name in
      let prFetchOptions = PHFetchOptions()
      prFetchOptions.predicate = NSPredicate(format: "title = %@", name)
      
      let result = PHAssetCollection.fetchAssetCollections(
        with: .album,
        subtype: .any,
        options: prFetchOptions
      )
      
      guard let first = result.firstObject else {
        throw AnyError("Couldn't find it.")
      }
      return first
    },
    create: { name in
      try await Future<PHAssetCollection, AnyError> { promise in
        var assetCollectionPlaceholder: PHObjectPlaceholder!
        
        PHPhotoLibrary.shared().performChanges({
          let createAlbumRequest = PHAssetCollectionChangeRequest
            .creationRequestForAssetCollection(withTitle: String.appPhotoAlbum)
          
          assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
          
        }, completionHandler: { success, error in
          guard success else {
            promise(.failure(AnyError("unableToGetCollection")))
            return
          }
          
          let collectionFetchResult = PHAssetCollection
            .fetchAssetCollections(
              withLocalIdentifiers: [assetCollectionPlaceholder.localIdentifier],
              options: nil
            )
          
          guard let assetCollection = collectionFetchResult.firstObject else {
            promise(.failure(AnyError("unableToGetCollection")))
            return
          }
          
          promise(.success(assetCollection))
        })
      }
      .value
    },
    save: { url, album in
      PHPhotoLibrary.shared().performChanges({
        let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        if let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset {
          let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
          albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
        }
      })
    }
  )
}

