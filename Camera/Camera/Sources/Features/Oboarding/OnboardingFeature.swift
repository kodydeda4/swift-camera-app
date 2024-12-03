import SwiftUI
import SwiftUINavigation
import ComposableArchitecture
import AVFoundation
import Photos

@Observable
@MainActor
final class OnboardingModel {
  var destination: Destination?
  var onCompletion: () -> Void
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  init(onCompletion: @escaping () -> Void = {}) {
    self.onCompletion = onCompletion
  }
  
  func continueButtonTapped() {
    self.destination = .userPermissions(
      UserPermissionsModel(
        delegate: .init(
          continueButtonTapped: { [weak self] in
            self?.onCompletion()
          }
        )
      )
    )
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
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  OnboardingView(model: OnboardingModel())
}
