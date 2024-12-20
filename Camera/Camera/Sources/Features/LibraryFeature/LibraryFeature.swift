import AVFoundation
import Dependencies
import IdentifiedCollections
import Photos
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class LibraryModel {
  var videos: IdentifiedArrayOf<Video> = []
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored @Dependency(\.uuid) var uuid
  @ObservationIgnored @SharedReader(.assetCollection) var collection
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary

  struct Video: Identifiable {
    var id: UUID
    let phAsset: PHAsset
    var avURLAsset: AVURLAsset?
    var thumbnail: UIImage?
  }
  
  @CasePathable
  enum Destination {
    case videoPlayer(VideoPlayerModel)
  }
  
  func buttonTapped(video: Video) {
    if let avURLAsset = video.avURLAsset {
      self.destination = .videoPlayer(VideoPlayerModel(
        phAsset: video.phAsset,
        avURLAsset: avURLAsset
      ))
    }
  }
  
  // @DEDA this should be reactive.
  func task() async {
    _ = await Result {
      guard let collection else {
        throw AnyError("collection was nil somehow.")
      }
      
      self.videos = []
      let fetchResult = try await self.photoLibrary.fetchAssets(.videos(in: collection))
      
      fetchResult.enumerateObjects { asset, _, _ in
        self.videos.append(.init(id: self.uuid(), phAsset: asset))
      }
      
      await withTaskGroup(of: Void?.self) { taskGroup in
        for video in self.videos {
          taskGroup.addTask {
            let avAsset = await self.photoLibrary.requestAVAsset(.init(asset: video.phAsset))?.asset
            let avURLAsset = (avAsset as? AVURLAsset)
            
            await MainActor.run {
              self.videos[id: video.id]?.avURLAsset = avURLAsset
            }

            if let avAsset {
              let uiImage = try? await self.photoLibrary.generateThumbnail(avAsset)
              
              await MainActor.run {
                self.videos[id: video.id]?.thumbnail = uiImage
              }
            }
          }
        }
      }
    }
  }
  
  private func bind() {
    switch destination {
      
    case let .videoPlayer(model):
      model.dismiss = { [weak self] in
        self?.destination = .none
      }
      
    case .none:
      break
    }
  }
}

// MARK: - SwiftUI

struct LibraryView: View {
  @Bindable var model: LibraryModel
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(
          columns: .init(repeating: GridItem(.flexible()), count: 2),
          spacing: 16
        ) {
          ForEach(model.videos) { video in
            self.videoView(video: video)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("Library")
      .task { await self.model.task() }
      .refreshable { await self.model.task() }
      .navigationDestination(item: $model.destination.videoPlayer) { model in
        VideoPlayerView(model: model)
      }
    }
  }
  
  @MainActor private func videoView(video: LibraryModel.Video) -> some View {
    Button {
      self.model.buttonTapped(video: video)
    } label: {
      if let uiImage = video.thumbnail {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFit()
          .cornerRadius(8)
          .padding(.horizontal)
      } else {
        ProgressView()
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  LibraryView(model: LibraryModel())
}
