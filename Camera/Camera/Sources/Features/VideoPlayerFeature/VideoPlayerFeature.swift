import AVFoundation
import AVKit
import Dependencies
import Photos
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

// @DEDA just load the mf before you nav here brh.

@MainActor
@Observable
final class VideoPlayerModel {
  let video: LibraryModel.Video
  var player: AVPlayer?
  var dismiss: () -> Void = unimplemented("VideoPlayerModel.dismiss")
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary

  init(video: LibraryModel.Video) {
    self.video = video
  }
 
  func task() async {
    if let avURLAsset = await self.photoLibrary.fetchAVURLAsset(self.video.asset) {
      self.player = AVPlayer(url: avURLAsset.url)
    }
  }

  func cancelButtonTapped() {
    self.dismiss()
  }
  
  func onVideoPlayerAppear() {
    self.player?.play()
  }
  
  func deleteButtonTapped() {
    Task {
      try await self.photoLibrary.delete(self.video.asset)
      self.dismiss()
    }
  }
}

// MARK: - SwiftUI

struct VideoPlayerView: View {
  @Bindable var model: VideoPlayerModel

  var body: some View {
    Group {
      if let player = self.model.player {
        VideoPlayer(player: player)
          .onAppear { self.model.onVideoPlayerAppear() }
      } else {
        Text("Loading video...")
      }
    }
    .task { await self.model.task() }
    .toolbar {
      Button("Delete") {
        self.model.deleteButtonTapped()
      }
    }
  }
}


// MARK: - SwiftUI Previews

// @DEDA plz fix
//#Preview {
//  VideoPlayerView(model: VideoPlayerModel())
//}
