import Combine
import Dependencies
import DependenciesMacros
import Photos
import UIKit

@DependencyClient
struct PhotoLibraryClient: Sendable {
  
  var fetchAssetCollections:
    @Sendable (FetchRequest.AssetCollection) async throws -> PHFetchResult<PHAssetCollection>
  
  var fetchAssets:
    @Sendable (FetchRequest.Assets) async throws -> PHFetchResult<PHAsset>
  
  var deleteAssets:
    @Sendable ([PHAsset]) async throws -> Void
  
  var requestAVAsset:
    @Sendable (FetchRequest.AVAsset) async -> RequestAVAssetResponse? = { _ in .none }
  
  var generateImage:
    @Sendable (AVAsset) async throws -> GenerateImageResponse?
  
  var createCollection2:
    @Sendable (String) async throws -> PHAssetCollection?
  
  var createCollection:
    @Sendable (_ title: String) async throws -> PHAssetCollection?
  
  var save:
    @Sendable (_ contentsOf: URL, _ toAssetCollection: PHAssetCollection) async throws -> Void
  
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
    struct AVAsset {
      let asset: PHAsset
      let options: PHVideoRequestOptions?
    }
  }
  
  typealias RequestAVAssetResponse = (
    asset: AVAsset?,
    audioMix: AVAudioMix?,
    dictionary: [AnyHashable : Any]?
  )
  
  typealias GenerateImageResponse = (image: CGImage, actualTime: CMTime)
}


extension DependencyValues {
  var photoLibrary: PhotoLibraryClient {
    get { self[PhotoLibraryClient.self] }
    set { self[PhotoLibraryClient.self] = newValue }
  }
}

extension PhotoLibraryClient: DependencyKey {
  static var liveValue = Self(
    fetchAssetCollections: { request in
      PHAssetCollection.fetchAssetCollections(
        with: request.type,
        subtype: request.subtype,
        options: request.options
      )
    },
    fetchAssets: { request in
      PHAsset.fetchAssets(
        in: request.collection,
        options: request.options
      )
    },
    deleteAssets: { assets in
      try await withCheckedThrowingContinuation { continuation in
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { success, error in
          if let error {
            continuation.resume(throwing: error)
          } else if success {
            continuation.resume()
          } else {
            fatalError("Response was neither success nor error.")
          }
        }
      }
    },
    requestAVAsset: { request in
      await withCheckedContinuation { continuation in
        PHImageManager.default().requestAVAsset(
          forVideo: request.asset,
          options: request.options,
          resultHandler: { asset, audioMix, dictionary in
            continuation.resume(
              returning: (
                asset: asset,
                audioMix: audioMix,
                dictionary: dictionary
              )
            )
          }
        )
      }
    },
    generateImage: { asset in
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      return try await generator.image(at: .zero)
    },
    createCollection2: { title in
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
    save: { url, album in
      PHPhotoLibrary.shared().performChanges({
        let assetChangeRequest = PHAssetChangeRequest
          .creationRequestForAssetFromVideo(atFileURL: url)
        
        if let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset {
          let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
          albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
        }
      })
    }
  )
}
