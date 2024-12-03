import SwiftUI

extension MainView {
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
      
      Text("AR Camera requires device permissions to work properly.")
        .fontWeight(.semibold)
        .foregroundColor(Color(.systemGray))

      Button(action: self.model.settingsButtonTapped) {
        Text("Settings")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .frame(width: 160)
      .padding(.bottom, 64)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .multilineTextAlignment(.center)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
