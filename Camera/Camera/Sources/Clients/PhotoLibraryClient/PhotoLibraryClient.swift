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
  
  var fetchAssetCollection: @Sendable (
    FetchRequest.AssetCollection
  ) async throws -> PHFetchResult<PHAssetCollection>
  
  var fetchAssets: @Sendable (
    FetchRequest.Assets
  ) async throws -> PHFetchResult<PHAsset>
  
  var fetchAVURLAsset: @Sendable (
    _ for: PHAsset
  ) async -> AVURLAsset? = { _ in .none }
  
  var fetchThumbnail: @Sendable (
    _ for: PHAsset
  ) async throws -> UIImage?
  
  var save: @Sendable (
    _ contentsOf: URL,
    _ toAssetCollection: PHAssetCollection
  ) async throws -> Void
  
  var delete: @Sendable (
    _ asset: [PHAsset]
  ) async throws -> Void
  
  struct FetchRequest {
    struct AssetCollection {
      let type: PHAssetCollectionType
      let subtype: PHAssetCollectionSubtype
      let options: PHFetchOptions?
    }
    struct Assets {
      let collection: PHAssetCollection
      let options: PHFetchOptions
    }
  }
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
    fetchAssetCollection: { request in
      PHAssetCollection.fetchAssetCollections(
        with: request.type,
        subtype: request.subtype,
        options: request.options
      )
    },
    fetchAssets: { request in
      PHAsset.fetchAssets(in: request.collection, options: request.options)
    },
    fetchAVURLAsset: { asset in
      await withCheckedContinuation { continuation in
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { avAsset, _, _ in
          continuation.resume(returning: (avAsset as? AVURLAsset))
        }
      }
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
            
            Task {
              if let cgImage = try? await assetGenerator.image(at: .zero).image {
                continuation.resume(returning: UIImage(cgImage: cgImage))
              } else {
                continuation.resume(throwing: AnyError("Couldn't create image"))
              }
            }
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
    delete: { assets in
      try await withCheckedThrowingContinuation { continuation in
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
          if let error {
            continuation.resume(throwing: error)
          } else if success {
            continuation.resume()
          }
        }
      }
    }
  )
}


