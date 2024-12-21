import Combine
import Dependencies
import DependenciesMacros
import Photos
import UIKit

/// @DEDA
/// This code provides an interface to Apple Photos API.
/// You can create static requests for things like CRUD operations or fetch requests.
/// This also allows you to have function labels for the requests.
///
/// - Example: `try await photosLibrary.performChanges(.createAssetCollection(withTitle: "App"))`
/// - Example: `try await photoLibrary.fetchAssets(.videos(in: collection))

@DependencyClient
struct PhotoLibraryClient: Sendable {

  var performChanges: @Sendable (
    Request.PhotoLibraryChange
  ) async throws -> Void

  var fetchAssetCollections: @Sendable (
    Request.AssetCollections
  ) async throws -> PHFetchResult<PHAssetCollection>

  var fetchAssets: @Sendable (
    Request.Assets
  ) async throws -> PHFetchResult<PHAsset>

  var requestAVAsset: @Sendable (
    _ asset: PHAsset,
    _ options: PHVideoRequestOptions?
  ) async -> Response.RequestAVAsset? = { _, _ in .none }
}

extension DependencyValues {
  var photoLibrary: PhotoLibraryClient {
    get { self[PhotoLibraryClient.self] }
    set { self[PhotoLibraryClient.self] = newValue }
  }
}

// MARK: - Types

extension PhotoLibraryClient {
  struct Request {
    struct PhotoLibraryChange {
      let rawValue: () -> Void
    }
    struct AssetCollections {
      let type: PHAssetCollectionType
      let subtype: PHAssetCollectionSubtype
      let options: PHFetchOptions?
    }
    struct Assets {
      let collection: PHAssetCollection
      let options: PHFetchOptions
    }
  }
  struct Response {
    struct RequestAVAsset {
      let asset: AVAsset?
      let audioMix: AVAudioMix?
      let dictionary: [AnyHashable : Any]?
    }
  }
}

// MARK: - Implementation

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
    requestAVAsset: { asset, options in
      await withCheckedContinuation { continuation in
        PHImageManager.default().requestAVAsset(
          forVideo: asset,
          options: options,
          resultHandler: { asset, audioMix, dictionary in
            continuation.resume(
              returning: Response.RequestAVAsset(
                asset: asset,
                audioMix: audioMix,
                dictionary: dictionary
              )
            )
          }
        )
      }
    }
  )
}

// MARK: - Requests

extension PhotoLibraryClient.Request.PhotoLibraryChange {
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

extension PhotoLibraryClient.Request.AssetCollections {
  static func albums(title: String) -> Self {
    Self(type: .album, subtype: .any, options: .make {
      $0.predicate = NSPredicate(format: "title = %@", title)
    })
  }
}

extension PhotoLibraryClient.Request.Assets {
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
