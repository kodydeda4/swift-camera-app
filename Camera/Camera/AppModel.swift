import SwiftUI

@Observable
@MainActor
final class AppModel {
  var userPermissions = UserPermissionsModel()
  
}

// MARK: - SwiftUI

struct AppView: View {
  @Bindable var model: AppModel
  
  var body: some View {
    NavigationStack {
      
     Text("AR Camera")
      
      NavigationLink("Continue") {
        UserPermissionsView(model: self.model.userPermissions)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  AppView(model: AppModel())
}
