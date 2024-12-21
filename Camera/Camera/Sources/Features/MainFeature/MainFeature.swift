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
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary
  
  enum Tab: Equatable {
    case library
    case camera
    case settings
  }
  
  func task() async {
    await self.syncPhotoLibrary()
  }
  
  // @DEDA cmon man.
  private func syncPhotoLibrary() async {
    let result = await Result<PHAssetCollection, Error> {
      
      var assetCollections = try await photoLibrary.fetchAssetCollections(
        .albums(title: self.assetCollectionTitle)
      )
      
      if assetCollections.count == 0 {
        try await photoLibrary.performChanges(
          .createAssetCollection(withTitle: self.assetCollectionTitle)
        )
      }
      
      assetCollections = try await photoLibrary.fetchAssetCollections(
        .albums(title: self.assetCollectionTitle)
      )
      
      if let first = assetCollections.firstObject {
        return first
      } else {
        throw AnyError(
          """
          Tried to create photo album with title: \(self.assetCollectionTitle),
          but fetchCollections(withTitle:) returned an empty result.
          """
        )
      }
    }
    
    if case let .success(value) = result {
      self.$assetCollection.withLock { $0 = value }
    }
    
    print("SyncPhotoLibrary", result)
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
  let value: Dictionary<
    UserPermissionsClient.Feature,
    UserPermissionsClient.Status
  > = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value
  
  MainView(model: MainModel())
}
