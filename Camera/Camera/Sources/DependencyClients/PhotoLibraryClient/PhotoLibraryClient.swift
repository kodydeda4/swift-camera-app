import Dependencies
import DependenciesMacros
import Photos

@DependencyClient
struct PhotoLibraryClient: Sendable {
  internal var _value: PHPhotoLibrary

  internal init(value: () -> PHPhotoLibrary) {
    self._value = value()
  }

  func callAsFunction() -> PHPhotoLibrary {
    self._value
  }
}

extension PhotoLibraryClient: DependencyKey {
  static var liveValue = Self { .shared() }
}

extension DependencyValues {
  var photoLibrary: PhotoLibraryClient {
    get { self[PhotoLibraryClient.self] }
    set { self[PhotoLibraryClient.self] = newValue }
  }
}
