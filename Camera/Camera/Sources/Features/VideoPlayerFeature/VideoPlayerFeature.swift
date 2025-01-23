import AVFoundation
import AVKit
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class VideoPlayerModel {
  let video: PhotosContext.Video
  let player: AVPlayer
  var dismiss: () -> Void = unimplemented("VideoPlayerModel.dismiss")
  var destination: Destination? { didSet { self.bind() } }

  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.uuid) var uuid

  @CasePathable
  enum Destination {
    case share(ActivityModel)
  }

  init(video: PhotosContext.Video) {
    self.video = video
    self.player = AVPlayer(url: video.avURLAsset.url)
  }

  func task() async {
    self.player.play()
  }

  func cancelButtonTapped() {
    self.dismiss()
  }

  func deleteButtonTapped() {
    Task {
      try await self.photos.performChanges(.delete(assets: [self.video.phAsset]))
      self.dismiss()
    }
  }

  func shareButtonTapped() {
    self.destination = .share(
      ActivityModel(
        activityItems: [
          ActivityItem(url: self.video.avURLAsset.url)
        ]
      )
    )
  }

  private func bind() {
    switch destination {

    case let .share(model):
      model.completionWithItemsHandler = { [weak self] _, _, _, _ in
        self?.destination = .none
      }

    case .none:
      break
    }
  }
}

// MARK: - SwiftUI

struct VideoPlayerView: View {
  @Bindable var model: VideoPlayerModel

  var body: some View {
    ZStack {
      VideoPlayer(player: self.model.player)
    }
    .task { await self.model.task() }
    .sheet(item: self.$model.destination.share) { model in
      ActivityView(model: model)
    }
    .toolbar {
      HStack {
        Button(action: self.model.shareButtonTapped) {
          Image(systemName: "square.and.arrow.up")
        }
        Button(action: self.model.deleteButtonTapped) {
          Image(systemName: "trash")
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews
//
//#Preview {
//  VideoPlayerView(model: VideoPlayerModel(
//    
//  ))
//}
