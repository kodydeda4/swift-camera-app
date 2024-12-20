import Dependencies
import Sharing
import Photos
import SwiftUI
import SwiftUINavigation
import CasePaths

/* --------------------------------------------------------------------------------------------
 
 @DEDA
 
 - [x] Camera
 - [x] Video Recording
 - [x] UserPermissions
 - [x] Bind && Unimplemented
 - [x] Destination
 - [x] Swift Dependencies
 - [x] Swift Format
 - [x] Build version
 - [x] AppIcon
 - [x] Front facing camera
 - [x] CameraClient
 - [x] SwiftUI Preview Compiler Directive
 - [x] Save to an app-specific-photo-album
 - [x] fetch and display videos from app-specific-photo-album.
 - [ ] CRUD the videos
 - [ ] Different zooms
 - [ ] Fix app backgrounding
 - [ ] Logs
 - [ ] Unit Tests
 - [ ] swift 6
 - [ ] SPM
 - [ ] App demo for onboarding
 - [ ] App demo for camera/mainfeature

 Idk Features
 - [ ] Handle app backgrounding
 - [ ] Share videos from roll
 - [ ] Record video vs take picture
 - [ ] Save to an album for the app specifically?
 - [ ] Notifications for when something was saved to your camera roll
 - [ ] video metadata or grdb?

  UI Rework
 - [ ] Sound effect when you tap a button.
 - [ ] Haptic feedback for recording button
 - [ ] Video Recording duration
 - [ ] Improve user permissions ui
 - [ ] Animations && UI Improvements (smooth transitions, loading screens..)
 - [ ] Finished recording toast / progress
 - [ ] DesignSystem

 -------------------------------------------------------------------------------------------- */

@Observable
@MainActor
final class AppModel {
  let assetCollectionTitle = PHAssetCollectionTitle.app.rawValue
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored @Shared(.isOnboardingComplete) var isOnboardingComplete = false
  @ObservationIgnored @Shared(.userPermissions) var userPermissions
  @ObservationIgnored @Shared(.assetCollection) var assetCollection
  @ObservationIgnored @Dependency(\.userPermissions) var userPermissionsClient
  @ObservationIgnored @Dependency(\.photoLibrary) var photoLibrary

  @CasePathable
  enum Destination {
    case main(MainModel)
    case onboarding(OnboardingModel)
  }
  
  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.syncUserPermissions()
        await self.syncPhotoLibrary()
        
        await MainActor.run {
          self.destination = self.isOnboardingComplete
          ? .main(MainModel())
          : .onboarding(OnboardingModel())
        }
      }
    }
  }
  
  /// Update user permissions when the app starts or returns from the background.
  private func syncUserPermissions() async {
    UserPermissionsClient.Feature.allCases.forEach { feature in
      self.$userPermissions.withLock {
        $0[feature] = self.userPermissionsClient.status(feature)
      }
    }
  }
  
  // @DEDA not sure about this logic yet bro.
  /// Load the existing photo library collection for the app if it exists, or try to create a new one.
  private func syncPhotoLibrary() async {
    let result = await Result<PHAssetCollection, Error> {
      if let existing = try await photoLibrary.fetchCollection(self.assetCollectionTitle) {
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

  private func bind() {
    switch destination {
      
    case .main:
      break
      
    case let .onboarding(model):
      model.onCompletion = { [weak self] in
        self?.$isOnboardingComplete.withLock { $0 = true }
        self?.destination = .main(MainModel())
      }
      
    case .none:
      break
    }
  }
}

// MARK: - SwiftUI

struct AppView: View {
  @Bindable var model: AppModel
  
  var body: some View {
    Group {
      switch self.model.destination {
        
      case let .main(model):
        MainView(model: model)
        
      case let .onboarding(model):
        OnboardingView(model: model)
        
      case .none:
        ProgressView()
      }
    }
    .task { await self.model.task() }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(model: AppModel())
}
