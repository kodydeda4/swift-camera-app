import AsyncAlgorithms
import AVFoundation
import AVFoundation
import AVFoundation
import IssueReporting
import Photos
import SwiftUI
import SwiftUINavigation
import UIKit

@Observable
@MainActor
final class ARObjectPickerModel: Identifiable {
  var dismiss: () -> Void = unimplemented("ARObjectPickerModel.dismiss")

  func cancelButtonTapped() {
    self.dismiss()
  }

  func saveButtonTapped() {
    self.dismiss()
  }
}

// MARK: - SwiftUI

struct ARObjectPickerSheet: View {
  @Bindable var model: ARObjectPickerModel

  var body: some View {
    NavigationStack {
      VStack {
        Text("AR Object Picker")

        Button("Save") {
          self.model.saveButtonTapped()
        }
      }
      .toolbar {
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
