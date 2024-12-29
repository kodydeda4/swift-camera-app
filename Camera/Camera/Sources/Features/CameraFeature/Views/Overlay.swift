import CasePaths
import Sharing
import SwiftUI

extension CameraView {
  internal func overlay() -> some View {
    VStack {
      Spacer()
      if self.model.hasFullPermissions {
        VStack {
          if self.model.isZoomButtonsPresented {
            HStack {
              ForEach([CGFloat]([0.5, 1, 2]), id: \.self) { zoom in
                self.zoomButton(zoom)
              }
            }
          }
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
  
  private func zoomButton(_ zoom: CGFloat) -> some View {
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

  private var cameraRollButton: some View {
    Group {
      if self.model.isCameraRollButtonPresented {
        Button {
          self.model.cameraRollButtonTapped()
        } label: {
          Group {
            if let uiImage = self.model.photosContext.videos.first?.thumbnail {
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
    }
  }

  private var recordingButton: some View {
    Button(action: self.model.recordingButtonTapped) {
      CameraRecordingButtonLabel(model: self.model)
    }
    .buttonStyle(.plain)
    .disabled(!self.model.hasFullPermissions)
  }

  // @DEDA formerly switch camera button
  // @DEDA idk why this mf is animating but it's annoying af.
  private var toggleSettingsButton: some View {
    let size: CGFloat = 30

    return Group {
      if self.model.isSettingsButtonPresented {
        Button(action: self.model.settingsButtonTapped) {
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
      }
    }
  }
}

fileprivate struct CameraRecordingButtonLabel: View {
  @Bindable var model: CameraModel

  private var innerCircleWidth: CGFloat {
    self.model.isRecording ? 32 : 55
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(lineWidth: 6)
        .foregroundColor(.white)
        .frame(width: 65, height: 65)

      RoundedRectangle(
        cornerRadius: self.model.isRecording ? 8 : self.innerCircleWidth / 2
      )
      .foregroundColor(self.model.destination.is(\.countdown) ? .white : .red)
      .frame(width: self.innerCircleWidth, height: self.innerCircleWidth)

    }
    .animation(.linear(duration: 0.2), value: self.model.isRecording)
    .padding(20)
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

#Preview("Camera") {
  @Shared(.userPermissions) var userPermissions = .authorized

  CameraView(model: CameraModel())
}

#Preview("Permissions Required") {
  @Shared(.userPermissions) var userPermissions = .denied

  CameraView(model: CameraModel())
}
