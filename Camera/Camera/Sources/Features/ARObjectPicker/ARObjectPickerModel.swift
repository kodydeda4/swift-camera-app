import IssueReporting
import SwiftUI
import Sharing

@Observable
@MainActor
final class ARObjectPickerModel: Identifiable {
  
  @ObservationIgnored
  @Shared var selection: EntityResource?
  
  var dismiss: () -> Void = unimplemented("ARObjectPickerModel.dismiss")
  
  public init(selection: Shared<EntityResource?> = Shared(value: .none)) {
    self._selection = selection
  }
  
  var isSaveButtonDisabled: Bool {
    self.selection == .none
  }
  
  func cancelButtonTapped() {
    self.dismiss()
  }
  
  func saveButtonTapped() {
    self.dismiss()
  }
  
  func entityResourceButtonTapped(_ value: EntityResource) {
    self.$selection.withLock { $0 = value }
  }
}

// MARK: - SwiftUI

struct ARObjectPickerSheet: View {
  @Bindable var model: ARObjectPickerModel
  // Define a grid layout with two columns
  private let columns = [
    GridItem(.flexible()), // First column
    GridItem(.flexible())  // Second column
  ]
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(EntityResource.allCases) { entityResource in
            Button {
              self.model.entityResourceButtonTapped(entityResource)
            } label: {
              self.entityResourceView(entityResource)
            }
            .buttonStyle(.plain)
          }
        }
        .padding()
      }
      .navigationTitle("AR Object")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(content: self.toolbar)
    }
  }
  
  @MainActor private func entityResourceView(
    _ entityResource: EntityResource
  ) -> some View {
    let isSelected = self.model.selection == entityResource
    let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    
    return VStack {
      Image(entityResource.rawValue)
        .resizable()
        .scaledToFit()
        .frame(width: 160, height: 160)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
          shape
            .strokeBorder(lineWidth: 2)
            .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .clipShape(shape)

      Text(entityResource.description)
        .foregroundColor(isSelected ? .accentColor : .secondary)
    }
    .frame(maxWidth: .infinity)
  }

  @MainActor private func toolbar() -> some ToolbarContent {
    Group {
      ToolbarItem(placement: .bottomBar) {
        Button {
          self.model.saveButtonTapped()
        } label: {
          Text("Save")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
        .disabled(self.model.isSaveButtonDisabled)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: self.model.cancelButtonTapped) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  Text("Hello World").sheet(isPresented: .constant(true)) {
    ARObjectPickerSheet(model: ARObjectPickerModel())
  }
}
