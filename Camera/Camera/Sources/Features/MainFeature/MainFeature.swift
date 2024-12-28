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
        guard let assetCollection = try? await self.fetchOrCreateAssetCollection(with: self.assetCollectionTitle) else {
          print("asset collection was nil.")
          return
        }
        await MainActor.run {
          self.$assetCollection.withLock { $0 = assetCollection }
        }
        
        for await fetchResult in await self.photos.streamAssets(.videos(in: assetCollection)) {
          await MainActor.run {
            fetchResult.enumerateObjects { asset, _, _ in
              self.$videos.withLock {
                $0[id: asset] = Video(phAsset: asset)
              }
            }
          }
        }
      }
//      for video in self.videos {
//        print("yo kody")
//
//        taskGroup.addTask {
//          let avAsset = await self.photos.requestAVAsset(
//            video.phAsset, .none
//          )?.asset
//
//          let avURLAsset = (avAsset as? AVURLAsset)
//
//          await MainActor.run {
//            self.$videos.withLock {
//              $0[id: video.id]?.avURLAsset = avURLAsset
//            }
//          }
//
//          if let avAsset, let image = try? await self.imageGenerator.image(avAsset)?.image {
//            await MainActor.run {
//              self.$videos.withLock {
//                $0[id: video.id]?.thumbnail = UIImage(cgImage: image)
//              }
//            }
//          }
//        }
//      }
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
