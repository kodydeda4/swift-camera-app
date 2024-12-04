import SwiftUI
import SwiftUINavigation
import AVFoundation
import Photos
import Sharing
import Dependencies

/* --------------------------------------------------------------------------------------------
 
 @DEDA
 
 - [x] Camera
 - [x] Video Recording
 - [x] UserPermissions
 - [x] Bind && Unimplemented
 - [x] Destination
 - [x] Swift Dependencies
 - [ ] SPM
 - [ ] SwiftUI Preview Compiler Directive
 - [ ] ARKit integration
 - [ ] Animations && UI Improvements (smooth transitions, loading screens..)
 - [ ] Build version
 - [ ] Finished recording toast / progress
 - [ ] DesignSystem
 - [ ] Logs
 - [ ] Swift Format
 - [ ] Unit Tests
 - [ ] swift 6
 - [ ] Git Flow release version

 Modern SwiftUI - PointFree
 https://github.com/pointfreeco/episode-code-samples/tree/main/0220-modern-swiftui-pt7
 
-------------------------------------------------------------------------------------------- */

@Observable
@MainActor
final class AppModel {
  var destination: Destination? { didSet { self.bind() } }

  @ObservationIgnored
  @Shared(.isOnboardingComplete) var isOnboardingComplete = false
  
  @ObservationIgnored
  @Shared(.userPermissions) var userPermissionsValues
  
  @ObservationIgnored
  @Dependency(\.userPermissions) var userPermissions

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
    await self.syncUserPermissions()
  }
  
  private func syncUserPermissions() async {
    UserPermissionsClient.Feature.allCases.forEach { feature in
      self.$userPermissionsValues.withLock {
        $0[feature] = self.userPermissions.status(feature)
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
