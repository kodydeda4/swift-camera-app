import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class MainModel {
  var cameraModel = CameraModel()
  var libraryModel = LibraryModel()
  var tab = Tab.camera
  
  enum Tab: Equatable {
    case library
    case camera
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
    }
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
