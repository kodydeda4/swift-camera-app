import SwiftUI
import AVFoundation
import Photos

protocol ApplicationServiceProtocol {
  func openSettings() throws
}

// MARK: - Live

final class ApplicationService: ApplicationServiceProtocol {
  func openSettings() throws {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      throw AnyError("UIApplication.openSettingsURLString is nil.")
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}
