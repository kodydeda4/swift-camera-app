import SwiftUI

extension MainView {
  internal func overlay() -> some View {
    VStack {
      self.top
      Spacer()
      self.bottom
    }
    .padding(64)
  }
  
  private var top: some View {
    Button("Settings") {
      self.model.settingsButtonTapped()
    }
  }

  private var bottom: some View {
    HStack {
      Button(action: self.model.deleteButtonTapped) {
        Image(systemName: "trash")
          .resizable()
          .scaledToFit()
          .frame(width: 32, height: 32)
      }
      .disabled(self.model.isDeleteButtonDisabled)
      
      Spacer()
      
      Button(action: self.model.newObjectButtonTapped) {
        Image(systemName: "plus")
          .resizable()
          .scaledToFit()
          .frame(width: 32, height: 32)
      }
      
      Spacer()
      
      Button(action: self.model.recordingButtonTapped) {
        Image(systemName: self.model.isRecording ? "circle.fill" : "circle")
          .resizable()
          .scaledToFit()
          .frame(width: 32, height: 32)
      }
    }
    .padding(.horizontal)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
