import SwiftUI
import SwiftUINavigation
import ComposableArchitecture

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
    self.destination = .userPermissions(
      UserPermissionsModel(
        delegate: UserPermissionsModel.Delegate(
          continueButtonTapped: { [weak self] in
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
        //@DEDA
//        MainView(model: model)
          .navigationBarBackButtonHidden()
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(model: AppModel())
}
