import SwiftUI
import SwiftUINavigation

@Observable
@MainActor
final class MainModel: Identifiable {
  
}

// MARK: - SwiftUI

struct MainView: View {
  @Bindable var model: MainModel
  
  var body: some View {
    Text("Main App")
  }
}

// MARK: - SwiftUI Previews

#Preview {
  NavigationStack {
    MainView(model: MainModel())
  }
}
