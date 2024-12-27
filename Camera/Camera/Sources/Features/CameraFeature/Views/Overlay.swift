import Sharing
import SwiftUI
import CasePaths

extension CameraView {
  internal func overlay() -> some View {
    VStack {
      Spacer()
      if self.model.hasFullPermissions {
        VStack {
          HStack {
            self.cameraRollButton
              .frame(maxWidth: .infinity)
            self.recordingButton
              .frame(maxWidth: .infinity)
            self.toggleSettingsButton
              .frame(maxWidth: .infinity)
          }
        }
        .padding(.bottom)
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .buttonStyle(.plain)
  }
}

fileprivate extension CameraView {

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
    Button {
      withAnimation {
        self.model.recordingButtonTapped()
      }
    } label: {
      CameraRecordingButtonLabel(isRecording: self.model.isRecording)
    }
    .buttonStyle(.plain)
    .disabled(!self.model.hasFullPermissions)
  }

  // @DEDA formerly switch camera button
  // @DEDA idk why this mf is animating but it's annoying af.
  private var toggleSettingsButton: some View {
    let size: CGFloat = 30
    
    return Button(action: self.model.toggleSettingsButtonTapped) {
      Image(systemName: !self.model.destination.is(\.settings) ? "ellipsis" : "xmark")
        .resizable()
        .scaledToFit()
        .fontWeight(.semibold)
        .frame(width: size, height: size)
        .padding(8)
        .background(
          !self.model.destination.is(\.settings)
          ? Color.black.opacity(0.5)
          : Color.white.opacity(0.1)
        )
        .foregroundColor(.white)
        .clipShape(Circle())
    }
    .padding(.horizontal)
    .disabled(self.model.isSwitchCameraButtonDisabled)
    .opacity(!self.model.isRecording ? 1 : 0.00000000001)
  }
}

fileprivate struct CameraRecordingButtonLabel: View {
  let isRecording: Bool

  private var innerCircleWidth: CGFloat {
    self.isRecording ? 32 : 55
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(lineWidth: 6)
        .foregroundColor(.white)
        .frame(width: 65, height: 65)

      RoundedRectangle(
        cornerRadius: self.isRecording ? 8 : self.innerCircleWidth / 2
      )
      .foregroundColor(.red)
      .frame(width: self.innerCircleWidth, height: self.innerCircleWidth)

    }
    .animation(.linear(duration: 0.2), value: self.isRecording)
    .padding(20)
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
