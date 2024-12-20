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
  var destination: Destination? { didSet { self.bind() } }
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary
  
  @CasePathable
  enum Destination {
    case share(URL)
  }

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
  
  func shareButtonTapped() {
    self.destination = .share(self.url)
  }
  
  private func bind() {
    switch destination {
      
    case .share:
      break
      
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
    .shareLink(item: self.$model.destination.share)
    .toolbar {
      HStack {
        Button("Share") {
          self.model.shareButtonTapped()
        }
        Button("Delete") {
          self.model.deleteButtonTapped()
        }
      }
    }
  }
}


// MARK: - SwiftUI Previews

// @DEDA plz fix
//#Preview {
//  VideoPlayerView(model: VideoPlayerModel())
//}
