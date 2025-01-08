import AVFoundation
import Dependencies
import IdentifiedCollections
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class LibraryModel: Identifiable {
  let id: UUID
  var destination: Destination? { didSet { self.bind() } }
  var dismiss: () -> Void
    = unimplemented("LibraryModel.dismiss")
  
  @ObservationIgnored @Shared(.photosContext) var photosContext
  @ObservationIgnored @Dependency(\.hapticFeedback) var hapticFeedback
  
  init() {
    @Dependency(\.uuid) var uuid
    self.id = uuid()
  }

  @CasePathable
  enum Destination {
    case videoPlayer(VideoPlayerModel)
  }
  
  func cancelButtonTapped() {
    self.hapticFeedback.generate(.soft)
    self.dismiss()
  }
  
  func buttonTapped(video: PhotosContext.Video) {
    self.destination = .videoPlayer(VideoPlayerModel(video: video))
  }
  
  func task() async {}
  
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
          ForEach(model.photosContext.videos) { video in
            self.videoView(video: video)
          }
        }
        .padding(.horizontal)
      }
      .navigationTitle("Library")
      .navigationBarTitleDisplayMode(.inline)
      .task { await self.model.task() }
      .refreshable { await self.model.task() }
      .navigationDestination(item: $model.destination.videoPlayer) { model in
        VideoPlayerView(model: model)
      }
      .overlay {
        VStack {
          Button(action: self.model.cancelButtonTapped) {
            Image(systemName: "xmark.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 60, height: 60)
              .foregroundColor(.secondary)
              .padding()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text("Library")
            .fontWeight(.semibold)
        }
        ToolbarItem(placement: .bottomBar) {
          Text("\(self.model.photosContext.videos.count) videos")
        }
      }
    }
  }
  
  @MainActor private func videoView(video: PhotosContext.Video) -> some View {
    Button {
      self.model.buttonTapped(video: video)
    } label: {
      Image(uiImage: video.thumbnail)
        .resizable()
        .scaledToFit()
        .overlay {
          VStack {
            Text(video.phAsset.duration.formattedDescription)
              .fontWeight(.semibold)
              .foregroundColor(.white)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
          .padding()
        }
        .padding(.horizontal)
        .cornerRadius(8)
    }
  }
}

//@DEDA probably not the perfect solution for this.
fileprivate extension TimeInterval {
  var formattedDescription: String {
    let minutes = Int(self) / 60
    let seconds = Int(self) % 60 + 1
    return "\(minutes):\(String(format: "%02d", seconds))"
  }
}


// MARK: - SwiftUI Previews

#Preview {
  LibraryView(model: LibraryModel())
}
