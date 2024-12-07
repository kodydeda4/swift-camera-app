import Dependencies
import DependenciesMacros
import Photos

@DependencyClient
struct PhotoLibraryClient: Sendable {
  var performChanges: @Sendable (@escaping () -> Void) -> Void
}

extension PhotoLibraryClient: DependencyKey {
  static var liveValue: Self {
    let photoLibrary = PHPhotoLibrary.shared()
    
    return Self(
      performChanges: {
        photoLibrary.performChanges($0)
      }
    )
  }
}

extension DependencyValues {
  var photoLibrary: PhotoLibraryClient {
    get { self[PhotoLibraryClient.self] }
    set { self[PhotoLibraryClient.self] = newValue }
  }
}
