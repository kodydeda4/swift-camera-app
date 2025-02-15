import Combine
import Dependencies
import DependenciesMacros
import Photos
import UIKit

@DependencyClient
struct PhotosLibraryClient: Sendable {
  
  var authorizationStatus: @Sendable (
    _ for: PHAccessLevel
  ) -> PHAuthorizationStatus = { _ in .notDetermined }
  
  var requestAuthorization: @Sendable (
    _ for: PHAccessLevel
  ) async -> PHAuthorizationStatus = { _ in .notDetermined }
  
  var performChanges: @Sendable (
    Request.PhotoLibraryChange
  ) async throws -> Void
  
  var fetchAssetCollections: @Sendable (
    Request.AssetCollections
  ) async throws -> PHFetchResult<PHAssetCollection>
  
  var fetchAssets: @Sendable (
    Request.Assets
  ) async throws -> PHFetchResult<PHAsset>
  
  var streamAssets: @Sendable (
    Request.Assets
  ) async -> AsyncStream<PHFetchResult<PHAsset>> = { _ in .finished }
  
  var requestAVAsset: @Sendable (
    _ asset: PHAsset,
    _ options: PHVideoRequestOptions?
  ) async -> Response.RequestAVAsset? = { _, _ in .none }
}

extension DependencyValues {
  var photos: PhotosLibraryClient {
    get { self[PhotosLibraryClient.self] }
    set { self[PhotosLibraryClient.self] = newValue }
  }
}

// MARK: - Types

extension PhotosLibraryClient {
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

extension PhotosLibraryClient: DependencyKey {
  static var liveValue = Self(
    authorizationStatus: { level in
      PHPhotoLibrary.authorizationStatus(for: level)
    },
    requestAuthorization: { level in
      await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    },
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
    streamAssets: { request in
      final class PhotoLibraryChangeObserver: NSObject, PHPhotoLibraryChangeObserver {
        private let handleChange: (PHChange) -> Void
        
        init(handleChange: @escaping (PHChange) -> Void) {
          self.handleChange = handleChange
        }
        
        func photoLibraryDidChange(_ change: PHChange) {
          handleChange(change)
        }
      }
      
      return AsyncStream { continuation in
        let fetchResult = PHAsset.fetchAssets(in: request.collection, options: request.options)
        
        continuation.yield(fetchResult)
        
        let observer = PhotoLibraryChangeObserver { change in
          if let changeDetails = change.changeDetails(for: fetchResult) {
            continuation.yield(changeDetails.fetchResultAfterChanges)
          }
        }
        
        PHPhotoLibrary.shared().register(observer)
        
        continuation.onTermination = { @Sendable _ in
          PHPhotoLibrary.shared().unregisterChangeObserver(observer)
        }
      }
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

