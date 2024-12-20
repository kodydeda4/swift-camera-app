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
  var inFlight: Bool = true
  var videos: IdentifiedArrayOf<Video> = []
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored @Shared(.assetCollection) var collection
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary
  
  struct Video: Identifiable {
    let id = UUID()
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
      
      self.videos = IdentifiedArray(
        uniqueElements: try await self.photoLibrary
          .fetchAssets(collection, .video)
          .map { Video(phAsset: $0) }
      )
      
      await withTaskGroup(of: Void?.self) { taskGroup in
        for video in self.videos {
          taskGroup.addTask {
            let uiImage = try? await self.photoLibrary.fetchThumbnail(video.phAsset)
            let avURLAsset = await self.photoLibrary.fetchAVURLAsset(video.phAsset)
            
            await MainActor.run {
              self.videos[id: video.id]?.thumbnail = uiImage
              self.videos[id: video.id]?.avURLAsset = avURLAsset
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
  private let columns = [GridItem(.flexible()), GridItem(.flexible())]
  
  var body: some View {
    NavigationStack {
      Group {
        if model.inFlight {
          ProgressView("Loading Videos...")
        } else if model.videos.isEmpty {
          Text("No videos found in your library.")
            .padding()
        } else {
          ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
              ForEach(model.videos) { video in
                self.videoView(video: video)
              }
            }
            .padding(.horizontal)
          }
        }
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
      }
    }
  }
}


// MARK: - SwiftUI Previews

#Preview {
  LibraryView(model: LibraryModel())
}
