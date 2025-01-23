import Foundation
import Sharing

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
  static var isOnboardingComplete: Self {
    Self[.appStorage("isOnboardingComplete"), default: false]
  }
}
