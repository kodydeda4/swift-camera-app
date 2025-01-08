import CasePaths
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

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
 - [x] CRUD the videos
 - [x] Share videos
 - [x] Different zooms
 - [x] Grid
 - [x] Add sounds for when the camera starts/stops
 - [x] display time in grid
 - [x] back camera zoom buttons on camera feature (without opening settings)
 - [ ] multi-select crud
 - [ ] Fix app backgrounding
 - [ ] Fix app rotation
 - [ ] Log4Swift
 - [ ] Unit Tests
 - [ ] swift 6
 - [ ] SPM
 - [ ] App demo for onboarding
 - [ ] App demo for camera/mainfeature
 - [ ] Slow motion settings?

 Photos
 - [x] Reactive (AsyncStream)
 - [x] Cached (@Shared(.inMemory))
 - [ ] Infinite Loading (.onAppear)

 Idk Features
 - [x] Save to an album for the app specifically?
 - [ ] Handle app backgrounding
 - [ ] Handle device rotation
 - [ ] Record video vs take picture
 - [ ] Notifications for when something was saved to your camera roll
 - [ ] video metadata or grdb?

  UI Rework
 - [x] Sound effect when you tap a button.
 - [x] Haptic feedback for recording button
 - [x] Video Recording duration
 - [ ] Improve user permissions ui
 - [ ] Animations && UI Improvements (smooth transitions, loading screens..)
 - [ ] Finished recording toast / progress
 - [ ] DesignSystem

 -------------------------------------------------------------------------------------------- */

@Observable
@MainActor
final class AppModel {
  var destination: Destination? { didSet { self.bind() } }

  @ObservationIgnored @Shared(.isOnboardingComplete) var isOnboardingComplete = false
  @ObservationIgnored @Shared(.userPermissions) var userPermissions
  @ObservationIgnored @Dependency(\.camera) var camera
  @ObservationIgnored @Dependency(\.audio) var audio
  @ObservationIgnored @Dependency(\.photos) var photos

  @CasePathable
  enum Destination {
    case main(MainModel)
    case onboarding(OnboardingModel)
  }

  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.syncUserPermissions()

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
    UserPermissions.Feature.allCases.forEach { feature in
      self.$userPermissions.withLock {
        $0[feature] = {
          switch feature {
          case .camera:
            switch self.camera.authorizationStatus(.video) {
            case .notDetermined: return .undetermined
            case .authorized: return .authorized
            default: return .denied
            }

          case .microphone:
            switch self.audio.recordPermission() {
            case .undetermined: return .undetermined
            case .granted: return .authorized
            default: return .denied
            }

          case .photos:
            switch self.photos.authorizationStatus(.addOnly) {
            case .notDetermined: return .undetermined
            case .authorized: return .authorized
            default: return .denied
            }
          }
        }()
      }
    }
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
