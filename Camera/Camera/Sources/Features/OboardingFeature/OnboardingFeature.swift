import AVFoundation
import IssueReporting
import Photos
import SwiftUI
import SwiftUINavigation

@Observable
@MainActor
final class OnboardingModel {
  var destination: Destination? { didSet { self.bind() } }
  var onCompletion: () -> Void = unimplemented("OnboardingModel.onCompletion")
  var buildVersion = Build.version

  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }

  func continueButtonTapped() {
    self.destination = .userPermissions(UserPermissionsModel())
  }

  private func bind() {
    switch destination {

    case let .userPermissions(model):
      model.onContinueButtonTapped = { [weak self] in
        self?.onCompletion()
      }

    case .none:
      break
    }
  }
}

// MARK: - SwiftUI

struct OnboardingView: View {
  @Bindable var model: OnboardingModel

  var body: some View {
    NavigationStack {
      VStack {
        LinearGradient(
          colors: [.accentColor, .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack {
          Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .foregroundColor(.accentColor)
            .padding()
            .background(Color.accentColor)
            .clipShape(Circle())

          Text("IDD Camera")
            .font(.title)
            .bold()

          Text("Welcome to your new Camera!")
            .font(.title2)
            .foregroundColor(.secondary)
            .padding(.bottom)

          Text(self.model.buildVersion.description)
            .foregroundColor(.secondary)

          Button("Continue") {
            self.model.continueButtonTapped()
          }
          .buttonStyle(RoundedRectangleButtonStyle(foregroundColor: .black))
        }
        .padding(32)
      }
      .navigationDestination(item: $model.destination.userPermissions) { model in
        UserPermissionsView(model: model)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  OnboardingView(model: OnboardingModel())
}
