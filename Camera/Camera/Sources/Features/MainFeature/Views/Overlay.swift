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
  private static let buttonSize: CGFloat = 24
  
  private var top: some View {
    HStack {
      Text("AR Camera")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.white)
      
      Spacer()
      
      Button(action: self.model.settingsButtonTapped) {
        Image(systemName: "gear")
          .resizable()
          .scaledToFit()
          .frame(width: Self.buttonSize, height: Self.buttonSize)
          .padding(8)
          .background(.regularMaterial)
          .foregroundColor(.accentColor)
          .clipShape(Circle())
      }
    }
  }

  private var bottom: some View {
    HStack {
      Button(action: self.model.deleteButtonTapped) {
        Image(systemName: "trash")
          .resizable()
          .scaledToFit()
          .frame(width: Self.buttonSize, height: Self.buttonSize)
          .foregroundColor(.red)
          .padding(8)
          .background(.regularMaterial)
          .clipShape(Circle())
      }
      .disabled(self.model.isDeleteButtonDisabled)
      
      Spacer()
      
      Button(action: self.model.newObjectButtonTapped) {
        Image(systemName: "plus")
          .resizable()
          .scaledToFit()
          .frame(width: Self.buttonSize, height: Self.buttonSize)
          .padding(8)
          .background(Color.blue)
          .foregroundColor(.white)
          .clipShape(Circle())
      }
      
      Spacer()
      
      Button(action: self.model.recordingButtonTapped) {
        Image(systemName: self.model.isRecording ? "circle.fill" : "circle")
          .resizable()
          .scaledToFit()
          .frame(width: Self.buttonSize, height: Self.buttonSize)
          .padding(8)
          .background(.regularMaterial)
          .foregroundColor(self.model.isRecording ? .red : .gray)
          .clipShape(Circle())
      }
    }
    .padding(.horizontal)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
