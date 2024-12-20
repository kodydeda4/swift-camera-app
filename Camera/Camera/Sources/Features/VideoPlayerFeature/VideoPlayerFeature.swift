import AVFoundation
import AVKit
import Dependencies
import Photos
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class VideoPlayerModel {
  let video: LibraryModel.Video
  var dismiss: () -> Void
    = unimplemented("VideoPlayerModel.dismiss")

  init(video: LibraryModel.Video) {
    self.video = video
  }

  func cancelButtonTapped() {
    self.dismiss()
  }
}

// MARK: - SwiftUI

struct VideoPlayerView: View {
  @Bindable var model: VideoPlayerModel
  @State private var player: AVPlayer? = nil

  var body: some View {
    Group {
      if let player = player {
        VideoPlayer(player: player)
          .onAppear {
            player.play()
          }
      } else {
        Text("Loading video...")
      }
    }
    .onAppear {
      fetchVideoURL(for: self.model.video.asset) { url in
        if let url = url {
          self.player = AVPlayer(url: url)
        } else {
          print("Failed to fetch video URL")
        }
      }
    }
  }

  // Helper function to fetch the video URL
  private func fetchVideoURL(for asset: PHAsset, completion: @escaping (URL?) -> Void) {
    PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { avAsset, _, _ in
      if let urlAsset = avAsset as? AVURLAsset {
        completion(urlAsset.url)
      } else {
        completion(nil)
      }
    }
  }
}


// MARK: - SwiftUI Previews

// @DEDA plz fix
//#Preview {
//  VideoPlayerView(model: VideoPlayerModel())
//}
