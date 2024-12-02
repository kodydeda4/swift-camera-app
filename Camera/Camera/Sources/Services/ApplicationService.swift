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
      throw AnyError("GG")
    }
    guard UIApplication.shared.canOpenURL(url) else {
      throw AnyError("GG")
    }
    UIApplication.shared.open(
      url,
      options: [:],
      completionHandler: nil
    )
  }
}
