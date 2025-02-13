import AVFoundation
import Dependencies
import IdentifiedCollections
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class MainModel {
  private(set) var cameraModel = CameraModel()
  
  @ObservationIgnored @Shared(.photosContext) var photosContext
  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.uuid) var uuid
  @ObservationIgnored @Dependency(\.imageGenerator) var imageGenerator
  
  func task() async {
    await withThrowingTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        let photosContext = try await self.fetchOrCreateAssetCollection(
          withTitle: PhotosContext.title
        )
        await MainActor.run {
          self.$photosContext.assetCollection.withLock { $0 = photosContext }
        }
        for await fetchResult in await self.photos.streamAssets(.videos(in: photosContext)) {
          await self.syncVideos(with: fetchResult)
        }
      }
    }
  }
  
  private func syncVideos(with fetchResult: PHFetchResult<PHAsset>) {
    let assets: [PHAsset] = (0..<fetchResult.count)
      .compactMap { fetchResult.object(at: $0) }
    
    self.$photosContext.videos.withLock { $0 = [] }
    
    Task {
      await withTaskGroup(of: Void.self) { taskGroup in
        for asset in assets {
          taskGroup.addTask {
            guard
              let avAsset = await self.photos.requestAVAsset(asset, .none)?.asset,
              let avURLAsset = (avAsset as? AVURLAsset),
              let thumbnail = try? await self.imageGenerator.image(avAsset)?.image
            else {
              return
            }
            await MainActor.run {
              self.$photosContext.videos.withLock {
                $0[id: asset] = PhotosContext.Video(
                  phAsset: asset,
                  avURLAsset: avURLAsset,
                  thumbnail: UIImage(cgImage: thumbnail)
                )
              }
            }
          }
        }
      }
    }
  }
  
  
  private func fetchOrCreateAssetCollection(
    withTitle title: String
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
      .createAssetCollection(withTitle: title)
    )
    
    albums = try await self.photos.fetchAssetCollections(
      .albums(with: title)
    )
    
    if let first = albums.firstObject {
      return first
    }
    
    // If that didn't work, throw an error.
    throw AnyError("Couldn't fetch or create asset collection.")
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
