import AVFoundation
import Dependencies
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class SettingsModel: Identifiable {
  let id = UUID()
  var buildNumber: Build.Version { Build.version }

  @ObservationIgnored @Shared(.userSettings) private(set) var userSettings
  @ObservationIgnored @Dependency(\.camera) var camera

  func cameraButtonTapped(_ value: UserSettings.Camera) {
    _ = Result {
      try self.camera.adjust(.position(value.rawValue))
      self.$userSettings.camera.withLock { $0 = value }
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

  func recordingQualityButtonTapped(value: UserSettings.RecordingQuality) {
    self.$userSettings.recordingQuality.withLock { $0 = value }
  }

  func gridButtonTapped(value: Bool) {
    self.$userSettings.isGridEnabled.withLock { $0 = value }
  }
}

// MARK: - SwiftUI

struct SettingsView: View {
  @Bindable var model: SettingsModel

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      self.divider.opacity(0.5)
      self.content
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

  @MainActor private var content: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text("Settings")
          .font(.title2)
          .fontWeight(.heavy)
          .foregroundColor(.white)
          .padding(.top, 8)

        Text("Camera \(self.model.buildNumber.description)")
          .foregroundColor(.white)
          .opacity(0.75)
          .padding(.bottom)

        self.divider
        VStack(alignment: .leading) {
          CameraSection(model: self.model)
          self.divider
          ZoomSection(model: self.model)
          self.divider
          CountdownTimerSection(model: self.model)
          self.divider
//          RecordingQualitySection(model: self.model)//@DEDA this is not implemented.
//          self.divider
          TorchModeSection(model: self.model)
          self.divider
          GridSection(model: self.model)
        }
      }
      .padding([.horizontal, .top])
      .shadow(color: Color.black, radius: 16, y: 12)
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

  private var divider: some View {
    Rectangle()
      .frame(height: 1)
      .foregroundColor(.white)
      .opacity(0.15)
  }
}

private struct Section<Content: View>: View {
  let systemImage: String
  let title: String
  let subtitle: String
  let content: () -> Content

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      self.header
      Spacer()
      HStack(content: self.content)
        .padding([.leading, .top], 8)
    }
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
      .padding(.bottom, 4)

      Text(subtitle)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .opacity(0.65)
    }
  }
}

private struct CameraSection: View {
  @Bindable var model: SettingsModel

  var body: some View {
    Section(
      systemImage: "camera",
      title: "Camera",
      subtitle: "Select a camera."
    ) {
      ForEach([UserSettings.Camera]([.front, .back]), id: \.self) { cameraPosition in
        button(cameraPosition)
      }
    }
  }

  private func button(_ camera: UserSettings.Camera) -> some View {
    let isSelected = self.model.userSettings.camera == camera

    return Button {
      self.model.cameraButtonTapped(camera)
    } label: {
      VStack {
        Text(camera.description)
          .font(.caption)
          .bold()
          .frame(width: 32, height: 32)
          .foregroundColor(isSelected ? .black : .white)
          .background(
            isSelected
              ? Color.accentColor
              : Color.white.opacity(0.25)
          )
          .clipShape(Circle())

        Text(camera.description)
          .font(.caption)
          .fontWeight(isSelected ? .bold : .regular)
          .foregroundColor(.white)
      }
    }
  }
}

private struct ZoomSection: View {
  @Bindable var model: SettingsModel

  var body: some View {
    Section(
      systemImage: "binoculars",
      title: "Zoom",
      subtitle: "Select the back camera zoom. "
    ) {
      ForEach([CGFloat]([0.5, 1, 2]), id: \.self) { zoom in
        button(zoom)
      }
      .disabled(self.model.userSettings.camera == .front)
    }
  }

  private func button(_ zoom: CGFloat) -> some View {
    let isSelected = self.model.userSettings.zoom == zoom

    return Button {
      self.model.zoomButtonTapped(zoom)
    } label: {
      VStack {
        Text("\(zoom.formattedDescription)x")
          .font(.caption)
          .bold()
          .frame(width: 32, height: 32)
          .foregroundColor(isSelected ? .black : .white)
          .background(
            isSelected
              ? Color.accentColor
              : Color.white.opacity(0.25)
          )
          .clipShape(Circle())

        Text("\(zoom.formattedDescription)x")
          .font(.caption)
          .fontWeight(isSelected ? .bold : .regular)
          .foregroundColor(.white)
      }
    }
  }
}

private struct CountdownTimerSection: View {
  @Bindable var model: SettingsModel

  var body: some View {
    Section(
      systemImage: "timer",
      title: "Timer",
      subtitle: "Create a timer before recording."
    ) {
      ForEach([0, 3, 5], id: \.self) { seconds in
        button(seconds)
      }
    }
  }

  private func button(_ seconds: Int) -> some View {
    let isSelected = self.model.userSettings.countdownTimer == seconds

    return Button {
      self.model.countdownTimerButtonTapped(value: seconds)
    } label: {
      VStack {
        Text("\(seconds.description)s")
          .font(.caption)
          .bold()
          .frame(width: 32, height: 32)
          .foregroundColor(isSelected ? .black : .white)
          .background(
            isSelected
              ? Color.accentColor
              : Color.white.opacity(0.25)
          )
          .clipShape(Circle())

        Text("\(seconds.description)s")
          .font(.caption)
          .fontWeight(isSelected ? .bold : .regular)
          .foregroundColor(.white)
      }
    }
  }
}

private struct RecordingQualitySection: View {
  @Bindable var model: SettingsModel

  var body: some View {
    Section(
      systemImage: "camera",
      title: "Recording Quality",
      subtitle: "Select a video recording quality."
    ) {
      HStack {
        ForEach(UserSettings.RecordingQuality.allCases) { quality in
          button(quality)
        }
      }
    }
  }

  private func button(_ quality: UserSettings.RecordingQuality) -> some View {
    let isSelected = self.model.userSettings.recordingQuality == quality

    return Button {
      self.model.recordingQualityButtonTapped(value: quality)
    } label: {
      VStack {
        Text("\(quality)")
          .font(.caption)
          .bold()
          .frame(width: 32, height: 32)
          .foregroundColor(isSelected ? .black : .white)
          .background(
            isSelected
              ? Color.accentColor
              : Color.white.opacity(0.25)
          )
          .clipShape(Circle())

        Text(quality.description)
          .font(.caption)
          .fontWeight(isSelected ? .bold : .regular)
          .foregroundColor(.white)
      }
    }
  }
}

private struct TorchModeSection: View {
  @Bindable var model: SettingsModel

  var body: some View {
    Section(
      systemImage: "bolt.fill",
      title: "Torch",
      subtitle: "Toggle torch on/off/auto."
    ) {
      ForEach(UserSettings.TorchMode.allCases) { torchMode in
        button(torchMode)
      }
      .disabled(self.model.userSettings.camera == .front)
    }
  }

  private func button(_ torchMode: UserSettings.TorchMode) -> some View {
    let isSelected = self.model.userSettings.torchMode == torchMode

    return Button {
      self.model.torchModeButtonTapped(value: torchMode)
    } label: {
      VStack {
        Text(torchMode.description)
          .font(.caption)
          .bold()
          .frame(width: 32, height: 32)
          .foregroundColor(isSelected ? .black : .white)
          .background(
            isSelected
              ? Color.accentColor
              : Color.white.opacity(0.25)
          )
          .clipShape(Circle())

        Text(torchMode.description)
          .font(.caption)
          .fontWeight(isSelected ? .bold : .regular)
          .foregroundColor(.white)
      }
    }
  }
}

private struct GridSection: View {
  @Bindable var model: SettingsModel

  var body: some View {
    Section(
      systemImage: "grid",
      title: "Grid",
      subtitle: "Toggle grid on/off."
    ) {
      HStack {
        ForEach([true, false], id: \.self) { isEnabled in
          button(isEnabled)
        }
      }
    }
  }

  private func button(_ isEnabled: Bool) -> some View {
    let isSelected = self.model.userSettings.isGridEnabled == isEnabled

    return Button {
      self.model.gridButtonTapped(value: isEnabled)
    } label: {
      VStack {
        Text(isEnabled ? "On" : "Off")
          .font(.caption)
          .bold()
          .frame(width: 32, height: 32)
          .foregroundColor(isSelected ? .black : .white)
          .background(
            isSelected
              ? Color.accentColor
              : Color.white.opacity(0.25)
          )
          .clipShape(Circle())

        Text(isEnabled ? "On" : "Off")
          .font(.caption)
          .fontWeight(isSelected ? .bold : .regular)
          .foregroundColor(.white)
      }
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
