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
  var buildNumber: Build.Version { Build.version }

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

          Text("Camera")
            .font(.title)
            .bold()

          Text("Record Videos.")
            .foregroundColor(.secondary)
            .padding(.bottom)

          Text(self.model.buildNumber.description)
          
          Button("Continue") {
            self.model.continueButtonTapped()
          }
          .buttonStyle(RoundedRectangleButtonStyle())
        }
        .padding(64)
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
