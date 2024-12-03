import SwiftUI
import SwiftUINavigation
import ComposableArchitecture
import AVFoundation
import Photos

@Observable
@MainActor
final class AppModel {
  var destination: Destination?
  
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
    : .onboarding(OnboardingModel(onCompletion: { [weak self] in
      self?.isOnboardingComplete = true
      self?.destination = .main(MainModel())
    }))
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
