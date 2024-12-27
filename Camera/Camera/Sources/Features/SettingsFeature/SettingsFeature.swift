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
  
  @ObservationIgnored @Shared(.camera) var camera
  @ObservationIgnored @Dependency(\.camera) var cameraClient
  
  @CasePathable
  enum Destination {
    case userPermissions(UserPermissionsModel)
  }
  
  var isZoomButtonsDisabled: Bool {
    self.camera.position == .front
  }
  
  func navigateToPermissions() {
    self.destination = .userPermissions(UserPermissionsModel())
  }
  
  func zoomButtonTapped(_ value: CGFloat) {
    _ = Result {
      try self.cameraClient.zoom(value)
      self.$camera.zoom.withLock { $0 = value }
    }
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
    //    NavigationStack {
    VStack(alignment: .leading) {
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
        HStack {
          HStack {
            Image(systemName: "binoculars")
            Text("Zoom")
              .bold()
          }
          Spacer()
          self.zoomButtons
        }
        .disabled(self.model.isZoomButtonsDisabled)
      }
      
      Spacer()
      
      Section {
        Text("Camera \(self.model.buildNumber.description)")
          .foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background { Color.black.opacity(0.75) }
    //      .navigationTitle("Settings")
    //      .toolbar {
    //        ToolbarItem(placement: .topBarTrailing) {
    //          Button(action: self.model.cancelButtonTapped) {
    //            Image(systemName: "xmark.circle.fill")
    //              .foregroundColor(.secondary)
    //          }
    //        }
    //      }
    //      .listStyle(.plain)
    //      .navigationDestination(item: $model.destination.userPermissions) { model in
    //        UserPermissionsSheet(model: model)
    //      }
  }
  
  private var zoomButtons: some View {
    HStack {
      ForEach([CGFloat]([0.5, 1, 2, 3]), id: \.self) { value in
        zoomButton(videoZoomFactor: value)
      }
    }
    .padding(8)
    .background {
      Color.white.opacity(0.5)
    }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
  
  private func zoomButton(videoZoomFactor value: CGFloat) -> some View {
    let isSelected = self.model.camera.zoom == value
    
    return Button {
      self.model.zoomButtonTapped(value)
    } label: {
      Text("\(value.formattedDescription)x")
        .font(.caption)
        .frame(width: 32, height: 32)
        .foregroundColor(isSelected ? .white : .black)
        .background(isSelected ? Color.black.opacity(0.65) : Color.white.opacity(0.5))
        .clipShape(Circle())
    }
  }
}

fileprivate extension CGFloat {
  var formattedDescription: String {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 0
    formatter.roundingMode = .halfUp
    return formatter.string(for: self)!
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
  
  SettingsView(model: SettingsModel())
}
