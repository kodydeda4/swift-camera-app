import Dependencies
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
 - [ ] Logs
 - [ ] Unit Tests
 - [ ] swift 6
 - [ ] SPM
 - [ ] Front facing camera
 - [ ] Different zooms
 - [ ] Camera Roll / Recorded video list w/preview and playback?..

  UI Rework
 - [ ] Video Recording duration
 - [ ] Improve user permissions ui
 - [ ] Animations && UI Improvements (smooth transitions, loading screens..)
 - [ ] Finished recording toast / progress
 - [ ] SwiftUI Preview Compiler Directive
 - [ ] DesignSystem


 -------------------------------------------------------------------------------------------- */

@Observable
@MainActor
final class AppModel {
  var destination: Destination? { didSet { self.bind() } }
  
  @ObservationIgnored
  @Shared(.isOnboardingComplete) var isOnboardingComplete = false
  
  @ObservationIgnored
  @Shared(.userPermissions) var userPermissions
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissionsClient
  
  @CasePathable
  enum Destination {
    case main(MainModel)
    case onboarding(OnboardingModel)
  }
  
  init() {
    self.destination = self.isOnboardingComplete
      ? .main(MainModel())
      : .onboarding(OnboardingModel())
  }
  
  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.syncUserPermissions()
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
