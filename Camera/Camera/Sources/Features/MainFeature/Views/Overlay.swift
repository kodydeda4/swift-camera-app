import SwiftUI

extension MainView {
  internal func overlay() -> some View {
    VStack {
      self.top
      Spacer()
      self.debug
      self.bottom
    }
    .frame(maxWidth: .infinity)
    .padding()
  }
}

fileprivate extension MainView {
  
  private var top: some View {
    HStack {
      Text("AR Camera")
        .fontWeight(.bold)
      
      Spacer()
      
      Button(action: self.model.settingsButtonTapped) {
        Image(systemName: "gear")
      }
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
