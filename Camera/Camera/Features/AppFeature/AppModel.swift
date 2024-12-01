import SwiftUI
import SwiftUINavigation

@Observable
@MainActor
final class AppModel {
  var destination: Destination?

  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
    case main(MainModel)
  }
  
  func continueButtonTapped() {
    // @DEDA
    // here is where you're supposed to check if you have permissions with some sort of shared state object or dependency.
    self.destination = .userPermissions(UserPermissionsModel(
      delegate: UserPermissionsModel.Delegate(continueButtonTapped: { [weak self] in
        self?.destination = .main(MainModel())
      })
    ))
  }
}

// MARK: - SwiftUI

struct AppView: View {
  @Bindable var model: AppModel
  
  var body: some View {
    NavigationStack {
      VStack {
        Text("AR Camera")
        
        Button("Continue") {
          self.model.continueButtonTapped()
        }
      }
      .sheet(item: $model.destination.userPermissions) { model in
        UserPermissionsView(model: model)
      }
      .fullScreenCover(item: $model.destination.main) { model in
        MainView(model: model)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(model: AppModel())
}
