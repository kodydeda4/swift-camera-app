import AVFoundation
import Dependencies
import Photos
import Sharing
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
final class CameraRollModel {
  //...
}

// MARK: - SwiftUI

struct CameraRollView: View {
  @Bindable var model: CameraRollModel
  
  var body: some View {
    NavigationStack {
      Text("Hi!")
    }
  }
}

// MARK: - SwiftUI Previews

//#Preview("Happy path") {
//  let value: Dictionary<
//    UserPermissionsClient.Feature,
//    UserPermissionsClient.Status
//  > = [
//    .camera: .authorized,
//    .microphone: .authorized,
//    .photos: .authorized,
//  ]
//  @Shared(.userPermissions) var userPermissions = value
#Preview {
  CameraRollView(model: CameraRollModel())
}
