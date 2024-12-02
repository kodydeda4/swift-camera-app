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
    case userPermissions(UserPermissionsModel)
    case main(MainModel)
  }
  
  init() {
    if self.isOnboardingComplete {
      self.destination = .main(MainModel())
    }
  }
  
  func continueButtonTapped() {
    self.destination = .userPermissions(
      UserPermissionsModel(
        delegate: .init(
          continueButtonTapped: { [weak self] in
            self?.isOnboardingComplete = true
            self?.destination = .main(MainModel())
          }
        )
      )
    )
  }
}

// MARK: - SwiftUI

struct AppView: View {
  @Bindable var model: AppModel
  
  var body: some View {
    NavigationStack {
      VStack {
        VStack {
          Spacer()
          
          Image(systemName: "camera.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .foregroundColor(.orange)
            .padding()
            .background(Color.orange.opacity(0.6))
            .clipShape(Circle())
          
          Text("AR Camera")
            .font(.title)
            .bold()
          
          Text("Record Videos with AR Objects.")
            .foregroundColor(.secondary)
            .padding(.bottom)
          
          Button("Continue") {
            self.model.continueButtonTapped()
          }
          .buttonStyle(.borderedProminent)
        }
        .padding(64)
      }
      .navigationDestination(item: $model.destination.userPermissions) { model in
        UserPermissionsView(model: model)
      }
      .navigationDestination(item: $model.destination.main) { model in
        MainView(model: MainModel())
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(model: AppModel())
}
