import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class MainModel {
  private(set) var cameraModel = CameraModel()
  let assetCollectionTitle = String.assetCollectionTitle
  
  @ObservationIgnored @Shared(.videos) var videos
  @ObservationIgnored @Shared(.assetCollection) var assetCollection
  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.uuid) var uuid
  @ObservationIgnored @Dependency(\.imageGenerator) var imageGenerator

  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.syncAssetCollection(Result {
          try await self.fetchOrCreateAssetCollection(with: self.assetCollectionTitle)
        })
        await self.syncVideos()
      }
    }
  }
  
  private func syncAssetCollection(_ response: Result<PHAssetCollection, Error>) {
    switch response {
      
    case let .success(value):
      self.$assetCollection.withLock { $0 = value }
      
    case let .failure(error):
      print(error.localizedDescription)
    }
  }
  
  private func fetchOrCreateAssetCollection(
    with title: String
  ) async throws -> PHAssetCollection {
    
    // Fetch collections with title.
    var albums = try await self.photos.fetchAssetCollections(
      .albums(with: title)
    )
    
    // If you found it, update and return.
    if let first = albums.firstObject {
      return first
    }
    
    // Else, try to create to the album, refetch, and update.
    try await self.photos.performChanges(
      .createAssetCollection(withTitle: self.assetCollectionTitle)
    )
    
    albums = try await self.photos.fetchAssetCollections(
      .albums(with: title)
    )
    
    if let first = albums.firstObject {
      return first
    }
    
    // If that didn't work, throw an error.
    throw AnyError("Couldn't fetch asset collection.")
  }
  
  
  private func syncVideos() async {
    _ = await Result {
      guard let assetCollection else {
        throw AnyError("collection was nil somehow.")
      }
      
      self.$videos.withLock { $0 = [] }
      let fetchResult = try await self.photos.fetchAssets(.videos(in: assetCollection))
      
      fetchResult.enumerateObjects { asset, _, _ in
        self.$videos.withLock {
          $0.append(.init(id: self.uuid(), phAsset: asset))
        }
      }
      
      await withTaskGroup(of: Void.self) { taskGroup in
        for video in self.videos {
          taskGroup.addTask {
            let avAsset = await self.photos.requestAVAsset(
              video.phAsset, .none
            )?.asset
            
            let avURLAsset = (avAsset as? AVURLAsset)
            
            await MainActor.run {
              self.$videos.withLock {
                $0[id: video.id]?.avURLAsset = avURLAsset
              }
            }

            if let avAsset, let image = try? await self.imageGenerator.image(avAsset)?.image {
              await MainActor.run {
                self.$videos.withLock {
                  $0[id: video.id]?.thumbnail = UIImage(cgImage: image)
                }
              }
            }
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable var model: MainModel
  
  var body: some View {
    CameraView(model: self.model.cameraModel)
      .task { await self.model.task() }
  }
}

// MARK: - SwiftUI Previews

#Preview("Happy path") {
  let value: UserPermissions.State = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value
  
  MainView(model: MainModel())
}
