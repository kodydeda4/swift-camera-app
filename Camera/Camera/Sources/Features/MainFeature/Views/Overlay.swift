import SwiftUI

private struct Style {
  static let buttonSize: CGFloat = 24
  static let buttonSizeRecording: CGFloat = 50
}

extension MainView {
  internal func overlay() -> some View {
    VStack {
      self.top
      Spacer()
      self.bottom
    }
    .frame(maxWidth: .infinity)
    .padding()
    .buttonStyle(.plain)
  }
}

fileprivate extension MainView {
  private var top: some View {
    HStack {
      Text("Camera")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(self.model.hasFullPermissions ? .white : .primary)

      Spacer()

      Button(action: self.model.permissionsButtonTapped) {
        Image(systemName: "gear")
          .resizable()
          .scaledToFit()
          .frame(width: Style.buttonSize, height: Style.buttonSize)
          .padding(8)
          .background(.regularMaterial)
          .foregroundColor(.accentColor)
          .clipShape(Circle())
      }
    }
  }

  private var bottom: some View {
    Button(action: self.model.recordingButtonTapped) {
      Image(systemName: self.model.isRecording ? "circle.fill" : "circle")
        .resizable()
        .scaledToFit()
        .fontWeight(.semibold)
        .frame(
          width: Style.buttonSizeRecording,
          height: Style.buttonSizeRecording
        )
        .padding(8)
        .background(.regularMaterial)
        .foregroundColor(self.model.isRecording ? .red : .gray)
        .clipShape(Circle())
    }
    .padding(.horizontal)
    .disabled(!self.model.hasFullPermissions)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
