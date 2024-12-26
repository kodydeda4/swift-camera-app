import Dependencies
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class SettingsModel: Identifiable {
  let id = UUID()
  var buildNumber: Build.Version { Build.version }
  var destination: Destination? { didSet { self.bind() } }
  var dismiss: () -> Void
    = unimplemented("Settings.dismiss")

  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  func navigateToPermissions() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func cancelButtonTapped() {
    self.dismiss()
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
            HStack {
              Label("Permissions", systemImage: "lock")
              Spacer()
              Image(systemName: "chevron.forward")
                .foregroundColor(.secondary)
            }
          }
        }
        
        Section {
          Text("Camera \(self.model.buildNumber.description)")
            .foregroundColor(.secondary)
        }
      }
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: self.model.cancelButtonTapped) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
          }
        }
      }
      .listStyle(.plain)
      .navigationDestination(item: $model.destination.userPermissions) { model in
        UserPermissionsSheet(model: model)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Happy path") {
  let value: UserPermissions.State = [
    .camera: .authorized,
    .microphone: .authorized,
    .photos: .authorized,
  ]
  @Shared(.userPermissions) var userPermissions = value
  
  CameraView(model: CameraModel())
}
