import AVFoundation
import Dependencies
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class SettingsModel: Identifiable {
  let id: UUID
  var buildVersion = Build.version
  
  @ObservationIgnored @Shared(.userSettings) private(set) var userSettings
  @ObservationIgnored @Dependency(\.camera) private var camera
  
  init() {
    @Dependency(\.uuid) var uuid
    self.id = uuid()
  }
  
  func cameraButtonTapped(_ value: UserSettings.Camera) {
    _ = Result {
      // 1. set camera
      try self.camera.adjust(.position(value.rawValue))
      self.$userSettings.camera.withLock { $0 = value }
      
      // 2. reset zoom
      self.$userSettings.zoom.withLock { $0 = 1.0 }
      
      // 3. reset torch
      self.$userSettings.torchMode.withLock { $0 = .off }
    }
  }
  
  var isZoomButtonsDisabled: Bool {
    self.userSettings.camera == .front
  }
  
  func zoomButtonTapped(_ value: CGFloat) {
    _ = Result {
      try self.camera.adjust(.videoZoomFactor(value))
      self.$userSettings.zoom.withLock { $0 = value }
    }
  }
  
  func countdownTimerButtonTapped(value: Int) {
    self.$userSettings.countdownTimer.withLock { $0 = value }
  }
  
  func torchModeButtonTapped(value: UserSettings.TorchMode) {
    _ = Result {
      try self.camera.adjust(.torchMode(value.rawValue))
      self.$userSettings.torchMode.withLock { $0 = value }
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

// MARK: - SwiftUI

struct SettingsView: View {
  @Bindable var model: SettingsModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      self.divider.opacity(0.5)
      
      ScrollView {
        VStack(alignment: .leading) {
          self.header
          self.content
        }
        .padding([.horizontal, .top])
        .shadow(color: Color.black, radius: 16, y: 12)
      }
      
      self.divider.opacity(0.5)
      self.footer
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
    .background { Color.black.opacity(0.75) }
  }
  
  private var divider: some View {
    Rectangle()
      .frame(height: 1)
      .foregroundColor(.white)
      .opacity(0.15)
  }
  
  private var header: some View {
    VStack(alignment: .leading) {
      Text("Settings")
        .font(.title2)
        .fontWeight(.heavy)
        .foregroundColor(.white)
        .padding(.top, 8)
      
      Text("Camera \(self.model.buildVersion.description)")
        .foregroundColor(.white)
        .opacity(0.75)
        .padding(.bottom)
      
      self.divider
    }
  }
  
  private var footer: some View {
    VStack(spacing: 0) {
      LinearGradient(
        colors: [
          Color.black.opacity(0.5),
          Color.black
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 70)
      
      Color.black
        .frame(height: 70)
    }
  }
  
  @MainActor private var content: some View {
    Group {
      self.cameraSection
      self.divider
      self.zoomSection
      self.divider
      self.torchModeSection
      self.divider
      self.countdownTimerSection
        .padding(.bottom)
    }
  }
  
  @MainActor private var cameraSection: some View {
    Section(
      systemImage: "camera",
      title: "Camera",
      subtitle: "Select a camera."
    ) {
      ForEach([UserSettings.Camera]([.front, .back]), id: \.self) { cameraPosition in
        Button(cameraPosition.description) {
          self.model.cameraButtonTapped(cameraPosition)
        }
        .buttonStyle(CircleButtonStyle(
          isSelected: self.model.userSettings.camera == cameraPosition
        ))
      }
    }
  }
  
  @MainActor private var zoomSection: some View {
    Section(
      systemImage: "binoculars",
      title: "Zoom",
      subtitle: "Select the back camera zoom. "
    ) {
      ForEach([CGFloat]([0.5, 1, 2]), id: \.self) { zoom in
        Button("\(zoom.formattedDescription)x") {
          self.model.zoomButtonTapped(zoom)
        }
        .buttonStyle(CircleButtonStyle(
          isSelected: self.model.userSettings.zoom == zoom
        ))
      }
      .disabled(self.model.userSettings.camera == .front)
    }
  }
  
  @MainActor private var countdownTimerSection: some View {
    Section(
      systemImage: "timer",
      title: "Timer",
      subtitle: "Create a timer before recording."
    ) {
      ForEach([0, 3, 5], id: \.self) { seconds in
        Button("\(seconds.description)s") {
          self.model.countdownTimerButtonTapped(value: seconds)
        }
        .buttonStyle(CircleButtonStyle(
          isSelected: self.model.userSettings.countdownTimer == seconds
        ))
      }
    }
  }
  
  @MainActor private var torchModeSection: some View {
    Section(
      systemImage: "bolt.fill",
      title: "Flash",
      subtitle: "Toggle flash on/off/auto."
    ) {
      ForEach(UserSettings.TorchMode.allCases) { torchMode in
        Button(torchMode.description) {
          self.model.torchModeButtonTapped(value: torchMode)
        }
        .buttonStyle(CircleButtonStyle(
          isSelected: self.model.userSettings.torchMode == torchMode
        ))
      }
      .disabled(self.model.userSettings.camera == .front)
    }
  }
}

private struct Section<Content: View>: View {
  let systemImage: String
  let title: String
  let subtitle: String
  let content: () -> Content
  
  var body: some View {
    HStack {
      self.header
      Spacer()
      HStack(content: self.content)
    }
    .padding(.vertical, 4)
  }
  
  private var header: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        Image(systemName: systemImage)
          .foregroundColor(.white)
        Text(title)
          .fontWeight(.heavy)
          .foregroundColor(.white)
      }
      .font(.title2)
      .padding(.bottom, 4)
      
//      Text(subtitle)
//        .fontWeight(.bold)
//        .foregroundColor(.white)
//        .opacity(0.65)
    }
  }
}

private struct CircleButtonStyle: ButtonStyle {
  let isSelected: Bool
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.footnote)
      .bold()
      .frame(width: 50, height: 50)
      .foregroundColor(isSelected ? .black : .white)
      .background(
        isSelected
        ? Color.accentColor
        : Color.white.opacity(0.25)
      )
      .clipShape(Circle())
      .scaleEffect(configuration.isPressed ? 0.9 : 1.0) // Adds a press animation
      .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
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
  
  NavigationStack {
    ZStack {
      VStack {}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
          Image(.cameraPreview)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
        }
        .overlay {
          VStack {
            Color.black
              .frame(height: 65)
            Spacer()
            Color.black
              .frame(height: 70)
          }
          .ignoresSafeArea()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
      
      SettingsView(model: SettingsModel())
    }
  }
}
