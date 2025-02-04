import CasePaths
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

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
