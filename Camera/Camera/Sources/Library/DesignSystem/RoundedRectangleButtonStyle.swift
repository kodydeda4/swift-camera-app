import SwiftUI

struct RoundedRectangleButtonStyle: ButtonStyle {
  var inFlight = false
  var foregroundColor = Color.white
  var backgroundColor = Color.accentColor
  var radius = CGFloat(8)
  var onPress: (() -> Void)? = {}
  
  func makeBody(configuration: Self.Configuration) -> some View {
    Group {
      if inFlight {
        ProgressView()
          .tint(foregroundColor)
      } else {
        configuration.label
      }
    }
    .fontWeight(.semibold)
    .foregroundColor(foregroundColor)
    .frame(height: 8*3)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity)
    .background {
      backgroundColor.overlay {
        Color.black.opacity(configuration.isPressed ? 0.25 : 0)
      }
    }
    .clipShape(RoundedRectangle(
      cornerRadius: radius,
      style: .continuous
    ))
    .animation(.default, value: configuration.isPressed)
    .onChange(of: configuration.isPressed) {
      if configuration.isPressed, let onPress {
        onPress()
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  Button("Click Me") {
    
  }
  .buttonStyle(RoundedRectangleButtonStyle(foregroundColor: .black))
  .padding()
}
