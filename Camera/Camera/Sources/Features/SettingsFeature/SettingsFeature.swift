import Dependencies
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class SettingsModel {
  var buildNumber: Build.Version { Build.version }
  var destination: Destination? { didSet { self.bind() } }
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  func navigateToPermissions() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  private func bind() {
    switch destination {
      
    case let .userPermissions(model):
      model.dismiss = { [weak self] in self?.destination = .none }
      
    case .none:
      break
    }
  }
}

// MARK: - SwiftUI

struct SettingsView: View {
  @Bindable var model: SettingsModel
  
  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            self.model.navigateToPermissions()
          } label: {
            Text("Permissions")
          }
        }
        Section {
          Text("\(model.buildNumber.description)")
        }
      }
      .navigationTitle("Settings")
      .navigationDestination(item: $model.destination.userPermissions) { model in
        UserPermissionsSheet(model: model)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Happy path") {
  let value: Dictionary<
    UserPermissionsClient.Feature,
    UserPermissionsClient.Status
  > = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value
  
  CameraView(model: CameraModel())
}
