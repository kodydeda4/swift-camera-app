import Sharing
import Foundation

extension SharedReaderKey where Self == FileStorageKey<Bool>.Default {
  static var isOnboardingComplete: Self {
    Self[.fileStorage(.shared("isOnboardingComplete.json")), default: false]
  }
}
