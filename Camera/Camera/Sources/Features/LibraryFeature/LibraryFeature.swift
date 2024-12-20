import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation
import Photos
import IdentifiedCollections

@MainActor
@Observable
final class LibraryModel {
  var inFlight: Bool = true
  var videos: IdentifiedArrayOf<Video> = []
  var selectedVideo: Video?
  
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary

  struct Video: Identifiable {
    let id = UUID()
    let asset: PHAsset
    var thumbnail: UIImage?
  }
  
  func buttonTapped(asset: Video) {
    self.selectedVideo = asset
  }
  
  // MARK: - Load Video Thumbnails
  
  func task() async {
    self.inFlight = true
    
    do {
      let collection = try await self.photoLibrary.fetchCollection(PhotosAlbum.app.rawValue)
      let videos = try await self.photoLibrary.fetchVideos(collection)
      self.videos = .init(uniqueElements: videos.map {
        Video(asset: $0)
      })
      
      await withTaskGroup(of: UIImage?.self) { taskGroup in
        for video in self.videos {
          taskGroup.addTask {
            let uiImage = try? await self.photoLibrary.fetchThumbnailFor(video.asset)
            
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
  
  func refresh() async {
    await self.task()
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
                if let uiImage = video.thumbnail {
                  Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .padding(.horizontal)
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
    }
  }
}


// MARK: - SwiftUI Previews

#Preview {
  LibraryView(model: LibraryModel())
}
