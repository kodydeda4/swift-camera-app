import Combine
import Dependencies
import DependenciesMacros
import Photos
import UIKit

@DependencyClient
struct PhotoLibraryClient: Sendable {
  
  var createCollection: @Sendable (
    _ withTitle: String
  ) async throws -> PHAssetCollection?
  
  var fetchCollection: @Sendable (
    _ withTitle: String
  ) async throws -> PHAssetCollection?
  
  var fetchAssets: @Sendable (
    _ in: PHAssetCollection,
    _ mediaType: PHAssetMediaType
  ) async throws -> [PHAsset]
  
  var fetchThumbnail: @Sendable (
    _ for: PHAsset
  ) async throws -> UIImage?
  
  var save: @Sendable (
    _ contentsOf: URL,
    _ toAssetCollection: PHAssetCollection
  ) async throws -> Void
  
  var delete: @Sendable (
    _ asset: PHAsset
  ) async throws -> Void
}

extension DependencyValues {
  var photoLibrary: PhotoLibraryClient {
    get { self[PhotoLibraryClient.self] }
    set { self[PhotoLibraryClient.self] = newValue }
  }
}

extension PhotoLibraryClient: DependencyKey {
  static var liveValue = Self(
    createCollection: { title in
      try await withCheckedThrowingContinuation { continuation in
        
        var assetCollectionPlaceholder: PHObjectPlaceholder!
        
        PHPhotoLibrary.shared().performChanges({
          assetCollectionPlaceholder = PHAssetCollectionChangeRequest
            .creationRequestForAssetCollection(withTitle: title)
            .placeholderForCreatedAssetCollection
          
        }, completionHandler: { success, error in
          
          if let error {
            continuation.resume(throwing: error)
          } else if success, let collection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [assetCollectionPlaceholder.localIdentifier],
            options: nil
          ).firstObject {
            continuation.resume(returning: collection)
          } else {
            continuation.resume(throwing: AnyError("@DEDA WTF?"))
          }
        })
      }
    },
    fetchCollection: { name in
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
    fetchAssets: { collection, mediaType in
      
      let assetsFetchOptions = PHFetchOptions()
      assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      assetsFetchOptions.predicate = NSPredicate(
        format: "mediaType == %d",
        mediaType.rawValue
      )
      
      let request = PHAsset.fetchAssets(in: collection, options: assetsFetchOptions)
      var assets: [PHAsset] = []
      request.enumerateObjects { asset, _, _ in
        assets.append(asset)
      }
      
      return assets
    },
    fetchThumbnail: { asset in
      try await withCheckedThrowingContinuation { continuation in
        let imageManager = PHImageManager.default()
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.deliveryMode = .highQualityFormat
        videoRequestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestAVAsset(
          forVideo: asset,
          options: videoRequestOptions
        ) { avAsset, _, _ in
          
          do {
            guard let avAsset else {
              continuation.resume(throwing: AnyError("Couldn't locate asset"))
              return
            }
            let assetGenerator = AVAssetImageGenerator(asset: avAsset)
            assetGenerator.appliesPreferredTrackTransform = true
            continuation.resume(returning: UIImage(cgImage: try assetGenerator.copyCGImage(
              at: .zero,
              actualTime: nil
            )))
          } catch {
            continuation.resume(throwing: AnyError("Couldn't create image"))
          }
        }
      }
    },
    save: { url, album in
      PHPhotoLibrary.shared().performChanges({
        let assetChangeRequest = PHAssetChangeRequest
          .creationRequestForAssetFromVideo(atFileURL: url)
        if let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset {
          let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
          albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
        }
      })
    },
    delete: { asset in
      try await withCheckedThrowingContinuation { continuation in
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
          if let error = error {
            continuation.resume(throwing: error)
          } else if success {
            continuation.resume()
          }
        }
      }
    }
  )
}

