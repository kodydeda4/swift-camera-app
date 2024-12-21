import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class MainModel {
  private(set) var cameraModel = CameraModel()
  private(set) var libraryModel = LibraryModel()
  private(set) var settingsModel = SettingsModel()
  
  var tab = Tab.camera
  let assetCollectionTitle = String.assetCollectionTitle
  
  @ObservationIgnored @Shared(.assetCollection) var assetCollection
  @ObservationIgnored @Dependency(\.photos) var photos
  
  enum Tab: Equatable {
    case library
    case camera
    case settings
  }
  
  func task() async {
    await self.syncAssetCollection(Result {
      try await self.fetchOrCreateAssetCollection(with: self.assetCollectionTitle)
    })
  }
  
  private func syncAssetCollection(_ response: Result<PHAssetCollection, Error>) {
    switch response {
      
    case let .success(value):
      self.$assetCollection.withLock { $0 = value }
      
    case let .failure(error):
      print(error.localizedDescription)
    }
  }
  
  private func fetchOrCreateAssetCollection(
    with title: String
  ) async throws -> PHAssetCollection {
    
    // Fetch collections with title.
    var albums = try await self.photos.fetchAssetCollections(
      .albums(with: title)
    )
    
    // If you found it, update and return.
    if let first = albums.firstObject {
      return first
    }
    
    // Else, try to create to the album, refetch, and update.
    try await self.photos.performChanges(
      .createAssetCollection(withTitle: self.assetCollectionTitle)
    )
    
    albums = try await self.photos.fetchAssetCollections(
      .albums(with: title)
    )
    
    if let first = albums.firstObject {
      return first
    }
    
    // If that didn't work, throw an error.
    throw AnyError("Couldn't fetch asset collection.")
  }
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable var model: MainModel
  
  var body: some View {
    TabView(selection: self.$model.tab) {
      LibraryView(model: self.model.libraryModel)
        .tabItem { Label("Library", systemImage: "square.grid.2x2") }
        .tag(MainModel.Tab.library)
      
      CameraView(model: self.model.cameraModel)
        .tabItem { Label("Camera", systemImage: "camera") }
        .tag(MainModel.Tab.camera)
      
      SettingsView(model: self.model.settingsModel)
        .tabItem { Label("Settings", systemImage: "gear") }
        .tag(MainModel.Tab.settings)
    }
    .task { await self.model.task() }
  }
}

// MARK: - SwiftUI Previews

#Preview("Happy path") {
  let value: UserPermissions.State = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value
  
  MainView(model: MainModel())
}
