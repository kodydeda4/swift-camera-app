import SwiftUI

// @DEDA extract this mf into a package m'boi.
struct CameraRecordingButton: View {
  let state: State
  var action: () -> Void
  
  enum State: Equatable {
    case `default`
    case recording
    case countdown
  }
  
  init(_ state: State, action: @escaping () -> Void) {
    self.state = state
    self.action = action
  }
  
  private var innerCircleWidth: CGFloat {
    self.state == .recording ? 32 : 55
  }
  
  var body: some View {
    Button {
      self.action()
    } label: {
      ZStack {
        Circle()
          .stroke(lineWidth: 6)
          .foregroundColor(.white)
          .frame(width: 65, height: 65)
        
        RoundedRectangle(
          cornerRadius: self.state == .recording ? 8 : self.innerCircleWidth / 2
        )
        .foregroundColor(self.state == .countdown ? .white : .red)
        .frame(width: self.innerCircleWidth, height: self.innerCircleWidth)
        
      }
      .animation(.linear(duration: 0.2), value: self.state == .recording)
      .padding(20)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - SwiftUI Preview

fileprivate struct CameraPreview: View {
  @State private var state = CameraRecordingButton.State.default
  
  private func buttonTapped() {
    if state == .default {
      state = .countdown
    } else if state == .countdown {
      state = .recording
    } else {
      state = .default
    }
  }
  
  var body: some View {
    Color.black.ignoresSafeArea().overlay {
      CameraRecordingButton(state) {
        buttonTapped()
      }
    }
  }
}

#Preview {
  CameraPreview()
}
