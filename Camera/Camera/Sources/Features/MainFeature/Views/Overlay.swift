import SwiftUI

extension MainView {
  internal func overlay() -> some View {
    VStack {
      self.top
      Spacer()
//      self.debug
      self.bottom
    }
    .frame(maxWidth: .infinity)
    .padding()
  }
}

fileprivate extension MainView {
  private static let buttonSize: CGFloat = 24
  
  private var top: some View {
    HStack {
      Text("AR Camera")
        .font(.title)
        .fontWeight(.bold)
      
      Spacer()
      
      Button(action: self.model.settingsButtonTapped) {
        Image(systemName: "gear")
          .resizable()
          .scaledToFit()
          .frame(width: Self.buttonSize, height: Self.buttonSize)
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
      }
      .disabled(self.model.isDeleteButtonDisabled)
      
      Spacer()
      
      Button(action: self.model.newObjectButtonTapped) {
        Image(systemName: "plus")
          .resizable()
          .scaledToFit()
          .frame(width: Self.buttonSize, height: Self.buttonSize)
      }
      
      Spacer()
      
      Button(action: self.model.recordingButtonTapped) {
        Image(systemName: self.model.isRecording ? "circle.fill" : "circle")
          .resizable()
          .scaledToFit()
          .frame(width: Self.buttonSize, height: Self.buttonSize)
      }
    }
    .padding(.horizontal)
  }
  
  
  @MainActor private var debug: some View {
    GroupBox {
      VStack(alignment: .leading) {
        debugLine("isPermissionGranted", self.model.isVideoPermissionGranted.description)
        debugLine("isCaptureSessionRunning", self.model.avCaptureSession.isRunning.description)
        debugLine("isRecording", self.model.isRecording.description)
      }
    }
    .padding()
  }
  
  @MainActor private func debugLine(_ title: String, _ description: String) -> some View {
    HStack {
      Text("\(title):")
        .bold()
      Text(description)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
