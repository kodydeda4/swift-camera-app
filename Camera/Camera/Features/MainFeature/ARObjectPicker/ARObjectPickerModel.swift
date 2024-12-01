import SwiftUI
import SwiftUINavigation
import AVFoundation
import UIKit
import AVFoundation
import AsyncAlgorithms
import AVFoundation
import Photos

@Observable
@MainActor
final class ARObjectPickerModel: Identifiable {
  var delegate: Delegate
  
  struct Delegate {
    var dismiss: () -> Void = {}
  }
  
  init(delegate: Delegate = .init()) {
    self.delegate = delegate
  }

  func cancelButtonTapped() {
    self.delegate.dismiss()
  }
  
  func saveButtonTapped() {
    self.delegate.dismiss()
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
