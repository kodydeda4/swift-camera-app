import Combine
import Dependencies
import DependenciesMacros
import Photos
import UIKit

@DependencyClient
struct PhotoLibraryClient: Sendable {
  
  var performChanges:
  @Sendable (AssetChangeRequest) async throws -> Void
  
  var fetchAssetCollections:
  @Sendable (FetchRequest.AssetCollection) async throws -> PHFetchResult<PHAssetCollection>
  
  var fetchAssets:
  @Sendable (FetchRequest.Assets) async throws -> PHFetchResult<PHAsset>
  
  var requestAVAsset:
  @Sendable (FetchRequest.AVAsset) async -> RequestAVAssetResponse? = { _ in .none }
  
  var generateImage:
  @Sendable (AVAsset) async throws -> GenerateImageResponse?
  
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
  
  struct AssetChangeRequest {
    let rawValue: () -> Void
  }
  
  typealias RequestAVAssetResponse = (
    asset: AVAsset?,
    audioMix: AVAudioMix?,
    dictionary: [AnyHashable : Any]?
  )
  
  typealias GenerateImageResponse = (
    image: CGImage,
    actualTime: CMTime
  )
}

extension DependencyValues {
  var photoLibrary: PhotoLibraryClient {
    get { self[PhotoLibraryClient.self] }
    set { self[PhotoLibraryClient.self] = newValue }
  }
}

extension PhotoLibraryClient: DependencyKey {
  static var liveValue = Self(
    performChanges: { request in
      try await withCheckedThrowingContinuation { continuation in
        PHPhotoLibrary.shared().performChanges({
          request.rawValue()
        }, completionHandler: { success, error in
          if let error {
            continuation.resume(throwing: error)
          } else if success {
            continuation.resume()
          } else {
            fatalError("Response was neither success nor error.")
          }
        })
      }
    },
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
    }
  )
}

extension PhotoLibraryClient.AssetChangeRequest {
  static func save(
    contentsOf url: URL,
    to assetCollection: PHAssetCollection
  ) -> Self {
    Self {
      let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      
      if let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset {
        let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
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


