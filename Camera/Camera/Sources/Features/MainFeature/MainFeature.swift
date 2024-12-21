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
  let assetCollectionTitle = PHAssetCollectionTitle.app.rawValue
  
  @ObservationIgnored @Shared(.assetCollection) var assetCollection
  @ObservationIgnored @Dependency(\.photos) var photos
  
  enum Tab: Equatable {
    case library
    case camera
    case settings
  }
  
  func task() async {
    await self.syncPhotoLibrary()
  }
  
  private func syncPhotoLibrary() async {
    // @DEDA Definetly room for improvement.
    let result = await Result<String, Error> {
      
      // Fetch collections with title.
      var assetCollections = try await self.photos.fetchAssetCollections(
        .albums(withTitle: self.assetCollectionTitle)
      )
      
      // If you found it, update and return.
      if let first = assetCollections.firstObject {
        self.$assetCollection.withLock { $0 = first }
        return "Success."
      }
      
      // Else, try to create to the album, refetch, and update.
      try await self.photos.performChanges(
        .createAssetCollection(withTitle: self.assetCollectionTitle)
      )
      assetCollections = try await self.photos.fetchAssetCollections(
        .albums(withTitle: self.assetCollectionTitle)
      )
      if let first = assetCollections.firstObject {
        self.$assetCollection.withLock { $0 = first }
        return "Success"
      }
      
      // If that didn't work, throw an error.
      throw AnyError("Couldn't fetch asset collection.")
    }
    
    print("MainModel.syncPhotoLibrary", result)
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
