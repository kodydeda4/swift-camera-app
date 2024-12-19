import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation
import Photos

// ayy the code kinda works but you need to specificy a photo album.

extension String {
  static let appPhotoAlbum = "KodysCameraApp"
}

@MainActor
@Observable
final class LibraryModel {
  var videoThumbnails: [UIImage] = []
  var inFlight: Bool = true
  
  // MARK: - Load Video Thumbnails
  func task() async {
    do {
      inFlight = true
      let videos = try await fetchVideosFromCameraRoll(fromAlbum: .appPhotoAlbum)
      videoThumbnails = await withTaskGroup(of: UIImage?.self) { group in
        for video in videos {
          group.addTask {
            await self.generateThumbnail(for: video)
          }
        }
        var thumbnails: [UIImage] = []
        for await thumbnail in group {
          if let thumbnail = thumbnail {
            thumbnails.append(thumbnail)
          }
        }
        return thumbnails
      }
    } catch {
      print("Error loading video thumbnails: \(error)")
    }
    inFlight = false
  }
  
  // MARK: - Fetch Videos
  private func fetchVideosFromCameraRoll(fromAlbum albumName: String) async throws -> [PHAsset] {
    return try await withCheckedThrowingContinuation { continuation in
      print("fetchVideosFromCameraRoll")
      
      // Fetch the album
      let fetchOptions = PHFetchOptions()
      fetchOptions.predicate = NSPredicate(format: "title == %@", albumName)
      let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
      
      guard let collection = collections.firstObject else {
        continuation.resume(throwing: NSError(domain: "LibraryModelError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Album not found"]))
        return
      }
      
      // Fetch videos from the album
      let assetsFetchOptions = PHFetchOptions()
      assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      assetsFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
      
      let assets = PHAsset.fetchAssets(in: collection, options: assetsFetchOptions)
      var videos: [PHAsset] = []
      assets.enumerateObjects { asset, _, _ in
        videos.append(asset)
      }
      continuation.resume(returning: videos)
    }
  }
  
  // MARK: - Generate Thumbnail
  private func generateThumbnail(for asset: PHAsset) async -> UIImage? {
    await withCheckedContinuation { continuation in
      let imageManager = PHImageManager.default()
      let videoRequestOptions = PHVideoRequestOptions()
      videoRequestOptions.deliveryMode = .highQualityFormat
      videoRequestOptions.isNetworkAccessAllowed = true
      
      imageManager.requestAVAsset(forVideo: asset, options: videoRequestOptions) { avAsset, _, _ in
        if let avAsset = avAsset {
          let assetGenerator = AVAssetImageGenerator(asset: avAsset)
          assetGenerator.appliesPreferredTrackTransform = true
          
          do {
            let cgImage = try assetGenerator.copyCGImage(at: .zero, actualTime: nil)
            continuation.resume(returning: UIImage(cgImage: cgImage))
          } catch {
            print("Error generating thumbnail: \(error)")
            continuation.resume(returning: nil)
          }
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }
}

// MARK: - SwiftUI

struct LibraryView: View {
  @Bindable var model: LibraryModel
  
  var body: some View {
    NavigationStack {
      Group {
        if model.inFlight {
          ProgressView("Loading Videos...")
        } else if model.videoThumbnails.isEmpty {
          Text("No videos found in your library.")
            .padding()
        } else {
          ScrollView {
            LazyVStack(spacing: 16) {
              ForEach(model.videoThumbnails.indices, id: \.self) { index in
                Image(uiImage: model.videoThumbnails[index])
                  .resizable()
                  .scaledToFit()
                  .cornerRadius(8)
                  .padding(.horizontal)
              }
            }
          }
        }
      }
      .navigationTitle("Library")
      .task { await self.model.task() }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  LibraryView(model: LibraryModel())
}

// MARK: - SwiftUI Previews

//#Preview("Happy path") {
//  let value: Dictionary<
//    UserPermissionsClient.Feature,
//    UserPermissionsClient.Status
//  > = [
//    .camera: .authorized,
//    .microphone: .authorized,
//    .photos: .authorized,
//  ]
//  @Shared(.userPermissions) var userPermissions = value
#Preview {
  LibraryView(model: LibraryModel())
}
