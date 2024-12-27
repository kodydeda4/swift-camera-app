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
    EmptyView()//@DEDA remove
  }
  
  private var bottom: some View {
    VStack {
      HStack {
        
              Button("Show bottom menu") {
                withAnimation {
                  count = 0
                }
                }
                

        self.cameraRollButton
          .frame(maxWidth: .infinity)
        CameraRecordingButton(model: model)
          .frame(maxWidth: .infinity)
        self.switchCameraButton
          .frame(maxWidth: .infinity)
      }
    }
  }
  
  private var cameraRollButton: some View {
    Button {
      self.model.navigateCameraRoll()
    } label: {
      Group {
        if let uiImage = self.model.latestVideoThumbnail {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .cornerRadius(8)
            .padding(.horizontal)
        } else {
          Color.blue
            .frame(width: 64, height: 64)
        }
      }
      .frame(width: 64, height: 64)
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


fileprivate struct CameraRecordingButton: View {
  @Bindable var model: CameraModel
  
  var body: some View {
    Button {
      withAnimation {
        self.model.recordingButtonTapped()
      }
    } label: {
      ZStack {
        Circle()
          .stroke(lineWidth: 6)
          .foregroundColor(.white)
          .frame(width: 65, height: 65)
        
        RoundedRectangle(
          cornerRadius: self.model.camera.isRecording ? 8 : self.innerCircleWidth / 2
        )
        .foregroundColor(.red)
        .frame(width: self.innerCircleWidth, height: self.innerCircleWidth)
        
      }
      .animation(.linear(duration: 0.2), value: self.model.camera.isRecording)
      .padding(20)
    }
    .buttonStyle(.plain)
  }
  
  private var innerCircleWidth: CGFloat {
    self.model.camera.isRecording ? 32 : 55
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
