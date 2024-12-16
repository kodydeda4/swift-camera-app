import SwiftUI

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

  struct Style {
    static let buttonSize: CGFloat = 24
    static let buttonSizeRecording: CGFloat = 50
  }

  private var top: some View {
    HStack {
      Text("AR Camera")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(self.model.hasFullPermissions ? .white : .primary)

      Spacer()

      Button(action: self.model.settingsButtonTapped) {
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
    HStack {
      self.deleteButton
      Spacer()
      self.recordingButton
      Spacer()
    }
    .padding(.horizontal)
    .disabled(!self.model.hasFullPermissions)
  }

  private var deleteButton: some View {
    Button(action: self.model.deleteButtonTapped) {
      Image(systemName: "trash")
        .resizable()
        .scaledToFit()
        .fontWeight(.semibold)
        .frame(width: Style.buttonSize, height: Style.buttonSize)
        .foregroundColor(.red)
        .padding(8)
        .background(.regularMaterial)
        .clipShape(Circle())
    }
    .disabled(self.model.isDeleteButtonDisabled)
  }

  private var recordingButton: some View {
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
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
