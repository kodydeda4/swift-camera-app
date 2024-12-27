import Dependencies
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class SettingsModel: Identifiable {
  let id = UUID()
  var buildNumber: Build.Version { Build.version }
  
  @ObservationIgnored @Shared(.camera) var camera
  @ObservationIgnored @Dependency(\.camera) var cameraClient
  
  var isZoomButtonsDisabled: Bool {
    self.camera.position == .front
  }
  
  func zoomButtonTapped(_ value: CGFloat) {
    _ = Result {
      try self.cameraClient.zoom(value)
      self.$camera.zoom.withLock { $0 = value }
    }
  }
}

// MARK: - SwiftUI

struct SettingsView: View {
  @Bindable var model: SettingsModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
      
      VStack(alignment: .leading) {
        Text("Settings")
          .font(.title2)
          .fontWeight(.heavy)
          .foregroundColor(.white)
          .padding(.vertical, 8)
        
        self.divider(padding: 0)
        
        VStack(alignment: .leading, spacing: 0) {
          self.zoom.disabled(self.model.isZoomButtonsDisabled)
          self.divider()
        }

        Text("Camera \(self.model.buildNumber.description)")
          .foregroundColor(.white)
          .opacity(0.75)
          .padding(.vertical)
      }
      .padding()
      .background { Color.black.opacity(0.55) }
      .background {
        LinearGradient(
          colors: [.black, .clear],
          startPoint: .bottom,
          endPoint: .top
        )
      }
      .clipShape(RoundedCornerShape(radius: 16, corners: [.topLeft, .topRight]))

      self.cameraControlsBackground
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .top
    )
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
  
  private var zoom: some View {
    HStack(alignment: .firstTextBaseline) {
      HStack {
        Image(systemName: "binoculars")
          .foregroundColor(.white)
        
        Text("Zoom")
          .fontWeight(.heavy)
          .foregroundColor(.white)
      }
      
      Spacer()
      self.zoomButtons
    }
  }
  
  private var zoomButtons: some View {
    HStack {
      ForEach([CGFloat]([0.5, 1, 2, 3]), id: \.self) { value in
        zoomButton(videoZoomFactor: value)
      }
    }
    .padding(8)
  }
  
  private func zoomButton(videoZoomFactor value: CGFloat) -> some View {
    let isSelected = self.model.camera.zoom == value
    
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

private struct RoundedCornerShape: Shape {
  var radius: CGFloat
  var corners: UIRectCorner
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
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
