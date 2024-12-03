import SwiftUI
import SwiftUINavigation
import ComposableArchitecture
import AVFoundation
import Photos

/* --------------------------------------------------------------------------------------------
 
 @DEDA
 
 - [x] Camera
 - [x] Video Recording
 - [x] UserPermissions
 - [x] Bind && Unimplemented
 - [x] Destination
 - [ ] SPM
 - [ ] SwiftUI Preview Compiler Directive
 - [ ] ARKit integration
 - [ ] Animations && UI Improvements (smooth transitions, loading screens..)
 - [ ] Build version
 - [ ] Finished recording toast / progress
 - [ ] Swift Dependencies
 - [ ] DesignSystem
 - [ ] Logs
 - [ ] Git Flow release version
 
 Modern SwiftUI - PointFree
 https://github.com/pointfreeco/episode-code-samples/tree/main/0220-modern-swiftui-pt7
 
-------------------------------------------------------------------------------------------- */

@Observable
@MainActor
final class AppModel {
  var destination: Destination? { didSet { self.bind() } }

  @ObservationIgnored
  @AppStorage(AppStorageKey.isOnboardingComplete.rawValue)
  var isOnboardingComplete = false
  
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

  private func bind() {
    switch destination {
      
    case .main:
      break
      
    case let .onboarding(model):
      model.onCompletion = { [weak self] in
        self?.isOnboardingComplete = true
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
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(model: AppModel())
}
