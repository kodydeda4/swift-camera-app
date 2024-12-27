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
  
  var isZoomButtonsDisabled: Bool {
    self.userSettings.cameraPosition == .front
  }
  
  func flashButtonTapped(value: Bool) {
    //@DEDA trigger flash to update.
    self.$userSettings.isFlashEnabled.withLock { $0 = value }
  }
  
  func timerButtonTapped(value: CGFloat) {
    //@DEDA handle somewhere else
    self.$userSettings.videoCaptureCountdownTimerDuration.withLock { $0 = value }
  }
  
  func recordingQualityButtonTapped(value: UserSettings.RecordingQuality) {
    //@DEDA handle somewhere else
    self.$userSettings.videoCaptureRecordingQuality.withLock { $0 = value }
  }

  func zoomButtonTapped(_ value: CGFloat) {
    _ = Result {
      try self.cameraClient.zoom(value)
      self.$userSettings.videoZoomFactor.withLock { $0 = value }
    }
  }
}

// MARK: - SwiftUI

struct SettingsView: View {
  @Bindable var model: SettingsModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
      self.content
      .padding()
      .background { Color.black.opacity(0.55) }
      .background {
        LinearGradient(
          colors: [.black, .clear],
          startPoint: .bottom,
          endPoint: .top
        )
      }
      .shadow(radius: 12)

      self.cameraControlsBackground
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
  }
  
  @MainActor private var content: some View {
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

      self.divider(padding: 0)
      ZoomSection(model: self.model)
      self.divider()
      TimerSection(model: self.model)
      self.divider()
      RecordingSection(model: self.model)
      self.divider()
      FlashSection(model: self.model)
    }
  }
  
  private var cameraControlsBackground: some View {
    VStack(spacing: 0) {
      Rectangle()
        .frame(height: 0.5)
        .foregroundColor(Color(.darkGray))
      Rectangle()
        .foregroundColor(.black)
        .frame(height: 150)
    }
  }
  
  private func divider(padding: CGFloat = 32) -> some View {
    Rectangle()
      .frame(height: 1)
      .foregroundColor(.white)
      .opacity(0.15)
      .padding(.leading, padding)
  }
}

private struct ZoomSection: View {
  @Bindable var model: SettingsModel

   var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        HStack {
          Image(systemName: "binoculars")
            .foregroundColor(.white)
          
          Text("Zoom")
            .fontWeight(.heavy)
            .foregroundColor(.white)
        }
        
        Spacer()
        
        HStack {
          ForEach([CGFloat]([0.5, 1, 2, 3]), id: \.self) { value in
            button(videoZoomFactor: value)
          }
        }
        .padding(8)
      }
    }
  }

  private func button(videoZoomFactor value: CGFloat) -> some View {
    let isSelected = self.model.userSettings.videoZoomFactor == value
    
    return Button {
      self.model.zoomButtonTapped(value)
    } label: {
      VStack {
        Text("\(value.formattedDescription)x")
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
        
        Text("\("Subtitle")")
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
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        HStack {
          Image(systemName: "timer")
            .foregroundColor(.white)
          
          Text("Timer")
            .fontWeight(.heavy)
            .foregroundColor(.white)
        }
        
        Spacer()
        
        HStack {
          ForEach([CGFloat]([0, 3, 5]), id: \.self) { value in
            button(seconds: value)
          }
        }
        .padding(8)
      }
    }
  }

  private func button(seconds value: CGFloat) -> some View {
    let isSelected = self.model.userSettings.videoCaptureCountdownTimerDuration == value

    return Button {
      self.model.timerButtonTapped(value: value)
    } label: {
      VStack {
        Text("\(value.formattedDescription)s")
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
        
        Text("\(value.formattedDescription)s")
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
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        HStack {
          Image(systemName: "camera")
            .foregroundColor(.white)
          
          Text("Recording")
            .fontWeight(.heavy)
            .foregroundColor(.white)
        }
        
        Spacer()
        
        HStack {
          ForEach(UserSettings.RecordingQuality.allCases) { value in
            button(quality: value)
          }
        }
        .padding(8)
      }
    }
  }

  private func button(quality value: UserSettings.RecordingQuality) -> some View {
    let isSelected = self.model.userSettings.videoCaptureRecordingQuality == value
    
    return Button {
      self.model.recordingQualityButtonTapped(value: value)
    } label: {
      VStack {
        Text("\(value)")
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
        
        Text(value.description)
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
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        HStack {
          Image(systemName: "bolt.fill")
            .foregroundColor(.white)
          
          Text("Flash")
            .fontWeight(.heavy)
            .foregroundColor(.white)
        }
        
        Spacer()
        
        HStack {
          button(isEnabled: true)
          button(isEnabled: false)
        }
        .padding(8)
      }
    }
  }

  private func button(isEnabled value: Bool) -> some View {
    let isSelected = self.model.userSettings.isFlashEnabled == value
    
    return Button {
      self.model.flashButtonTapped(value: value)
    } label: {
      VStack {
        Text(value ? "On" : "Off")
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
        
        Text(value ? "Enabled" : "Disabled")
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
