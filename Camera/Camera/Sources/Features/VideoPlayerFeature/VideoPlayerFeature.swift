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
  let asset: PHAsset
  let url: URL
  let player: AVPlayer
  var dismiss: () -> Void = unimplemented("VideoPlayerModel.dismiss")
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary
  
  init(asset: PHAsset, url: URL) {
    self.asset = asset
    self.url = url
    self.player = AVPlayer(url: url)
  }
  
  func task() async {
    self.player.play()
  }
  
  func cancelButtonTapped() {
    self.dismiss()
  }
  
  func deleteButtonTapped() {
    Task {
      try await self.photoLibrary.delete([self.asset])
      self.dismiss()
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
