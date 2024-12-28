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
  public let id = UUID()
  @ObservationIgnored @Shared(.videos) var videos
  var destination: Destination? { didSet { self.bind() } }
  var dismiss: () -> Void
    = unimplemented("Library.dismiss")
  
  @CasePathable
  enum Destination {
    case videoPlayer(VideoPlayerModel)
  }
  
  func cancelButtonTapped() {
    self.dismiss()
  }
  
  func editButtonTapped() {
    //...@DEDA unimplemented
  }
  
  func buttonTapped(video: Video) {
    if let avURLAsset = video.avURLAsset {
      self.destination = .videoPlayer(VideoPlayerModel(
        phAsset: video.phAsset,
        avURLAsset: avURLAsset
      ))
    }
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
          ForEach(model.videos) { video in
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: self.model.editButtonTapped) {
            Text("Edit")
              .fontWeight(.semibold)
              .foregroundColor(.accentColor)
          }
        }
        ToolbarItem(placement: .principal) {
          Text("Library")
            .fontWeight(.semibold)
        }
        ToolbarItem(placement: .bottomBar) {
          Text("\(self.model.videos.count) videos")
        }
      }
    }
  }
  
  @MainActor private func videoView(video: Video) -> some View {
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
