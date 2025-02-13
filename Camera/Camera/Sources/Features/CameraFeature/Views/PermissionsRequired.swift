import SwiftUI

extension CameraView {
  @MainActor var permissionsRequired: some View {
    VStack {
      Image(systemName: "camera.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 60, height: 60)
        .foregroundColor(.secondary)

      Text("Permissions Required")
        .font(.title2)
        .fontWeight(.bold)

      Text("Camera requires device permissions to work properly.")
        .fontWeight(.semibold)
        .foregroundColor(Color(.systemGray))

      Button("Permissions") {
        self.model.permissionsButtonTapped()
      }
      .buttonStyle(RoundedRectangleButtonStyle(foregroundColor: .black))
      .frame(width: 160)
      .padding(.bottom, 64)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .multilineTextAlignment(.center)
    .padding(.horizontal)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  CameraView(model: CameraModel())
}
