import Dependencies
import Sharing
import SwiftUI
import SwiftUINavigation
import AVFoundation

// @DEDA
// Settings need to be resent to camera view on appear.
// when you connect to the video preview layer, you can
// send all of your state from userSettings.

@MainActor
@Observable
final class SettingsModel: Identifiable {
  let id = UUID()
  var buildNumber: Build.Version { Build.version }
  
  @ObservationIgnored @Shared(.userSettings) var userSettings
  @ObservationIgnored @Dependency(\.camera) var cameraClient
  
  func cameraPositionButtonTapped(_ value: UserSettings.CameraPosition) {
    _ = Result {
      try self.cameraClient.setCameraPosition(value.rawValue)
      self.$userSettings.cameraPosition.withLock { $0 = value }
    }
  }

  var isZoomButtonsDisabled: Bool {
    self.userSettings.cameraPosition == .front
  }

  func zoomButtonTapped(_ value: CGFloat) {
    _ = Result {
      try self.cameraClient.zoom(value)
      self.$userSettings.videoZoomFactor.withLock { $0 = value }
    }
  }
  
  func timerButtonTapped(value: CGFloat) {
    //@DEDA handle somewhere else
    self.$userSettings.videoCaptureCountdownTimerDuration.withLock { $0 = value }
  }

  func flashButtonTapped(value: Bool) {
    //@DEDA trigger flash to update.
    self.$userSettings.isFlashEnabled.withLock { $0 = value }
  }
  
  func recordingQualityButtonTapped(value: UserSettings.RecordingQuality) {
    //@DEDA handle somewhere else
    self.$userSettings.videoCaptureRecordingQuality.withLock { $0 = value }
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
    .background { Color.black.opacity(0.7) }
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
        CameraSection(model: self.model)
        self.divider
        ZoomSection(model: self.model)
        self.divider
        TimerSection(model: self.model)
        self.divider
        RecordingSection(model: self.model)
        self.divider
        FlashSection(model: self.model)
      }
      .padding([.horizontal, .top])
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
        .padding(8)
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
      subtitle: "Lorem ipsum"
    ) {
      ForEach([UserSettings.CameraPosition]([.front, .back]), id: \.self) { cameraPosition in
        button(cameraPosition)
      }
    }
  }

  private func button(_ cameraPosition: UserSettings.CameraPosition) -> some View {
    let isSelected = self.model.userSettings.cameraPosition == cameraPosition
    
    return Button {
      self.model.cameraPositionButtonTapped(cameraPosition)
    } label: {
      VStack {
        Text(cameraPosition.description)
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
        
        Text(cameraPosition.description)
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
      subtitle: "Lorem ipsum"
    ) {
      ForEach([CGFloat]([0.5, 1, 2, 3]), id: \.self) { zoom in
        button(zoom)
      }
    }
  }

  private func button(_ zoom: CGFloat) -> some View {
    let isSelected = self.model.userSettings.videoZoomFactor == zoom
    
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

private struct TimerSection: View {
  @Bindable var model: SettingsModel
  
  var body: some View {
    Section(
      systemImage: "timer",
      title: "Timer",
      subtitle: "Lorem ipsum"
    ) {
      ForEach([CGFloat]([0, 3, 5]), id: \.self) { seconds in
        button(seconds)
      }
    }
  }

  private func button(_ seconds: CGFloat) -> some View {
    let isSelected = self.model.userSettings.videoCaptureCountdownTimerDuration == seconds

    return Button {
      self.model.timerButtonTapped(value: seconds)
    } label: {
      VStack {
        Text("\(seconds.formattedDescription)s")
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
        
        Text("\(seconds.formattedDescription)s")
          .font(.caption)
          .fontWeight(isSelected ? .bold : .regular)
          .foregroundColor(.white)
      }
    }
  }
}

private struct RecordingSection: View {
  @Bindable var model: SettingsModel
  
  var body: some View {
    Section(
      systemImage: "camera",
      title: "Recording",
      subtitle: "Lorem ipsum"
    ) {
      HStack {
        ForEach(UserSettings.RecordingQuality.allCases) { quality in
          button(quality)
        }
      }
    }
  }

  private func button(_ quality: UserSettings.RecordingQuality) -> some View {
    let isSelected = self.model.userSettings.videoCaptureRecordingQuality == quality
    
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

private struct FlashSection: View {
  @Bindable var model: SettingsModel

  var body: some View {
    Section(
      systemImage: "bolt.fill",
      title: "Flash",
      subtitle: "Lorem ipsum"
    ) {
      HStack {
        ForEach([true, false], id: \.self) { isEnabled in
          button(isEnabled)
        }
      }
    }
  }

  private func button(_ isEnabled: Bool) -> some View {
    let isSelected = self.model.userSettings.isFlashEnabled == isEnabled
    
    return Button {
      self.model.flashButtonTapped(value: isEnabled)
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
        
        Text(isEnabled ? "Enabled" : "Disabled")
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
