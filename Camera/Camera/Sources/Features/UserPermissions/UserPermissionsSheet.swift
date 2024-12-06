import SwiftUI

struct UserPermissionsSheet: View {
  @Bindable var model: UserPermissionsModel

  var body: some View {
    NavigationStack {
      UserPermissionsView(model: self.model).toolbar {
        Button(action: self.model.cancelButtonTapped) {
          Image(systemName: "xmark.circle.fill")
        }
        .buttonStyle(.plain)
        .foregroundColor(Color(.systemGray2))
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  Text("Hello World").sheet(isPresented: .constant(true)) {
    UserPermissionsSheet(model: UserPermissionsModel())
  }
}
