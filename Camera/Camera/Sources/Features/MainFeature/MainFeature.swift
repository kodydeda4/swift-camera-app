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

  // @DEDA not sure about this logic yet bro.
  // i think it breaks if you don't give full access.
  /// Load the existing photo library collection for the app if it exists, or try to create a new one.
  private func syncPhotoLibrary() async {

    let result = await Result<PHAssetCollection, Error> {
      if let existing = try? await photoLibrary.fetchCollection(self.assetCollectionTitle) {
        return existing
      } else if let new = try? await photoLibrary.createCollection(self.assetCollectionTitle) {
        return new
      } else {
        throw AnyError("SyncPhotoLibrary, failed to fetch or create collection.")
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
