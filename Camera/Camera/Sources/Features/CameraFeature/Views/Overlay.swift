import Sharing
import SwiftUI

private struct Style {
  static let buttonSize: CGFloat = 24
  static let buttonSizeRecording: CGFloat = 50
}

extension CameraView {
  internal func overlay() -> some View {
    VStack {
      self.top
      Spacer()
      if self.model.hasFullPermissions {
        self.bottom
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .buttonStyle(.plain)
  }
}

fileprivate extension CameraView {
  private var top: some View {
    VStack(alignment: .leading) {
      Text("Camera")
        .font(.title)
        .fontWeight(.bold)
      
      Text(self.model.buildNumber.description)
    }
    .foregroundColor(self.model.hasFullPermissions ? .white : .primary)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var bottom: some View {
    VStack {
      switch self.model.camera.position {
        
      case .front:
        self.zoomButtons.padding(.bottom)
        
      default:
        EmptyView()
        //...
      }
      
      HStack {
        self.recordingButton
        Spacer()
        self.switchCameraButton
      }
    }
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
        //        .padding()
        .background(isSelected ? Color.black.opacity(0.65) : Color.white.opacity(0.5))
        .clipShape(Circle())
    }
  }
  
  private var recordingButton: some View {
    Button(action: self.model.recordingButtonTapped) {
      Image(systemName: self.model.camera.isRecording ? "circle.fill" : "circle")
        .resizable()
        .scaledToFit()
        .fontWeight(.semibold)
        .frame(
          width: Style.buttonSizeRecording,
          height: Style.buttonSizeRecording
        )
        .padding(8)
        .background(.regularMaterial)
        .foregroundColor(self.model.camera.isRecording ? .red : .gray)
        .clipShape(Circle())
    }
    .padding(.horizontal)
    .disabled(!self.model.hasFullPermissions)
  }
  
  private var switchCameraButton: some View {
    Button(action: self.model.switchCameraButtonTapped) {
      Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
        .resizable()
        .scaledToFit()
        .fontWeight(.semibold)
        .frame(
          width: Style.buttonSizeRecording,
          height: Style.buttonSizeRecording
        )
        .padding(8)
        .background(.regularMaterial)
        .foregroundColor(self.model.camera.isRecording ? .red : .gray)
        .clipShape(Circle())
    }
    .padding(.horizontal)
    .disabled(self.model.isSwitchCameraButtonDisabled)
  }
}

extension CGFloat {
  var formattedDescription: String {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 0
    formatter.roundingMode = .halfUp
    return formatter.string(for: self)!
  }
}

// MARK: - SwiftUI Previews

#Preview("Camera") {
  @Shared(.userPermissions) var userPermissions = .authorized
  
  CameraView(model: CameraModel())
}

#Preview("Permissions Required") {
  @Shared(.userPermissions) var userPermissions = .denied
  
  CameraView(model: CameraModel())
}
