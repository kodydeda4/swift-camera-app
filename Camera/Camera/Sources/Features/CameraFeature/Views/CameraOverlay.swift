import CasePaths
import Sharing
import SwiftUI

struct CameraOverlay: View {
  @Bindable var model: CameraModel
  
  var body: some View {
    VStack {
      Spacer()
      self.zoomButtons
      
      HStack {
        self.cameraRollButton
        self.recordingButton
        self.toggleSettingsButton
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
    .padding(.bottom)
    .buttonStyle(.plain)
  }
  
  private var zoomButtons: some View {
    Group {
      if self.model.isZoomButtonsPresented {
        HStack {
          ForEach([CGFloat]([0.5, 1, 2]), id: \.self) { zoom in
            Button {
              self.model.zoomButtonTapped(zoom)
            } label: {
              self.zoomButtonLabel(zoom)
            }
          }
        }
      }
    }
  }
  
  private func zoomButtonLabel(_ zoom: CGFloat) -> some View {
    let isSelected = self.model.userSettings.zoom == zoom
    
    return Text("\(zoom.formattedDescription)x")
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
          .frame(maxWidth: .infinity)
        }
      }
    }
  }
  
  private var recordingButton: some View {
    CameraRecordingButton(self.model.cameraRecordingButtonState) {
      self.model.recordingButtonTapped()
    }
    .buttonStyle(.plain)
    .disabled(!self.model.hasFullPermissions)
    .frame(maxWidth: .infinity)
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
    .frame(maxWidth: .infinity)
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
  @Shared(.userSettings) var userSettings

  return CameraView(model: CameraModel())
}

#Preview("Permissions Required") {
  @Shared(.userPermissions) var userPermissions = .denied
  
  CameraView(model: CameraModel())
}
