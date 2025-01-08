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

  private func zoomButton(_ zoom: CGFloat) -> some View {
    let isSelected = self.model.userSettings.zoom == zoom

    return Button {
      self.model.zoomButtonTapped(zoom)
    } label: {
      Text("\(zoom.formattedDescription)x")
        .font(.caption)
        .bold()
        .frame(width: 32, height: 32)
        .foregroundColor(isSelected ? .black : .white)
        .background(
          isSelected
          ? Color.accentColor
          : Color.black.opacity(0.5)
        )
        .clipShape(Circle())
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
              Color.secondary
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                  RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(.systemGray2))
                }
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

  private var toggleSettingsButton: some View {
    let size: CGFloat = 30
    let settings = self.model.destination.is(\.settings)

    return Group {
      if self.model.isSettingsButtonPresented {
        Button(action: self.model.settingsButtonTapped) {
          ZStack {
            if settings {
              Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .padding(6)
            } else {
              Image(systemName: "ellipsis")
                .resizable()
                .scaledToFit()
                .padding(4)
            }
          }
          .fontWeight(.semibold)
          .frame(width: size, height: size)
          .padding(8)
          .background {
            settings ? Color.white.opacity(0.1) : Color.black.opacity(0.5)
          }
          .foregroundColor(.white)
          .clipShape(Circle())
        }
        .padding(.horizontal)
        .animation(.none, value: settings)
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
