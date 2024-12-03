import SwiftUI

extension MainView {
  @MainActor var notEnoughPermissions: some View {
    VStack {
      Text("Permissions aren't setup br0")
      
      Button("Fix") {
        self.model.settingsButtonTapped()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - SwiftUI Previews

#Preview {
  MainView(model: MainModel())
}
