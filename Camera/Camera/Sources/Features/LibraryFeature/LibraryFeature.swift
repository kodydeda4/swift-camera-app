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
    let asset: PHAsset
    var thumbnail: UIImage?
  }

  @CasePathable
  enum Destination {
    case videoPlayer(VideoPlayerModel)
  }

  func buttonTapped(video: Video) {
    self.destination = .videoPlayer(VideoPlayerModel(video: video))
  }

  func task() async {
    await self.fetchVideos()
  }

  func refresh() async {
    await self.fetchVideos()
  }

  private func fetchVideos() async {
    self.inFlight = true

    do {
      guard let collection else {
        throw AnyError("collection was nil somehow.")
      }

      let videos = try await self.photoLibrary.fetchAssets(collection, .video)

      self.videos = IdentifiedArray(uniqueElements: videos.map { Video(asset: $0) })

      await withTaskGroup(of: UIImage?.self) { taskGroup in
        for video in self.videos {
          taskGroup.addTask {
            let uiImage = try? await self.photoLibrary.fetchThumbnail(video.asset)

            await MainActor.run {
              self.videos[id: video.id]?.thumbnail = uiImage
            }

            return uiImage
          }
        }
      }
    } catch {
      print(error.localizedDescription)
    }
    inFlight = false
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
}


// MARK: - SwiftUI Previews

#Preview {
  LibraryView(model: LibraryModel())
}
