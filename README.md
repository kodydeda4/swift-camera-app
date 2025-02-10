# 📸 SwiftUI Camera App

A SwiftUI-based camera app with video recording, sharing, playback, and deletion functionalities.

Available on the [AppStore](https://apps.apple.com/us/app/idd-camera/id6740935223) now!

[![IDD Camera App Store Badge](https://github.com/user-attachments/assets/25ef15ca-5a73-447b-affa-a0b26a1d7082)](https://apps.apple.com/us/app/idd-camera/id6740935223)

<img width=150 src="https://github.com/user-attachments/assets/53de5b6e-cadc-494e-89b7-6bde399ffcd1"><img width=150 src="https://github.com/user-attachments/assets/b2a6cef6-feb2-4b86-af2a-bc39689377e7"><img width=150 src="https://github.com/user-attachments/assets/4424ec3d-146d-4736-bbca-78b87168f61e"><img width=150 src="https://github.com/user-attachments/assets/38a60968-b48f-4d03-bedc-fe91b935b8c3"><img width=150 src="https://github.com/user-attachments/assets/ae0ee5b6-886c-4571-a9ea-bdfc36cd72f7">

🛠️ Tech Stack
SwiftUI: For building the user interface
AVFoundation: For camera and video recording functionalities.
Swift-Concurrency: For reactive programming and handling data flow.
MVVM: Application architecture
UIKit: Lightweight integrations with existing UIKit views.

## 🚀 Features

### User Permissions

<img width=250 src="https://github.com/user-attachments/assets/01cf4f9b-b961-40d7-a2fb-1252caf6b31b">  

User permissions are requested with [swift-dependencies](https://github.com/pointfreeco/swift-dependencies), and stored as a dictionary using [swift-sharing](https://github.com/pointfreeco/swift-sharing).

### Camera

<img width=250 src="https://github.com/user-attachments/assets/da4c9d95-5f4f-40f3-b473-bf3f0e39a8e2">  

```swift
@MainActor
@Observable
final class CameraModel {
  var captureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  ...
  @ObservationIgnored @Dependency(\.camera) var camera
  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.audioPlayer) var audioPlayer
}
```


### Countdown

<img width=250 src="https://github.com/user-attachments/assets/b5bb16c2-abd4-41cd-89f6-62c1b5ad9780">  

```swift
@MainActor
@Observable
final class CountdownModel: Identifiable {
  ...
  var onFinish: () -> Void
    = unimplemented("CountdownModel.onFinish")
  @ObservationIgnored @SharedReader(.userSettings) var userSettings
}
```

### Settings

<img width=250 src="https://github.com/user-attachments/assets/e5a154ff-e4e3-407f-b7eb-2c5ce1caf64a">  

```swift
struct UserSettings: Equatable, Codable {
  var camera = Camera.back
  var zoom: CGFloat = 1
  var countdownTimer = 0
  var torchMode = TorchMode.off
  var isGridEnabled = false
  ...
}

extension SharedReaderKey where Self == FileStorageKey<UserSettings>.Default {
  static var userSettings: Self {
    Self[.fileStorage(.shared("userSettings")), default: UserSettings()]
  }
}
```

### Library

<img width=250 src="https://github.com/user-attachments/assets/c30ad8ba-0c65-473f-9bfe-44c460edf9b8">  

```swift
@MainActor
@Observable
final class LibraryModel: Identifiable {
  ...
  @ObservationIgnored @Shared(.photosContext) var photosContext

  @CasePathable
  enum Destination {
    case videoPlayer(VideoPlayerModel)
  }
}
```

### Video Player

<img width=250 src="https://github.com/user-attachments/assets/34d6dfe5-b118-4847-bb49-daf0661b14bb">  

```swift
@MainActor
@Observable
final class VideoPlayerModel {
  let video: PhotosContext.Video
  ...
  @CasePathable
  enum Destination {
    case share(ActivityModel)
  }
}
```

### Share

<img width=250 src="https://github.com/user-attachments/assets/7602daa1-dd5f-43f2-aebe-c32c741e3032">

```swift
@MainActor
@Observable
final class ActivityModel: Identifiable {
  let id: UUID
  let activityItems: [UIActivityItemProvider]
  let applicationActivities: [UIActivity]
  var completionWithItemsHandler: UIActivityViewController
    .CompletionWithItemsHandler = unimplemented("ActivityModel.completionWithItemsHandler")

  init(
    activityItems: [UIActivityItemProvider],
    applicationActivities: [UIActivity] = []
  ) {
    @Dependency(\.uuid) var uuid
    self.id = uuid()
    self.activityItems = activityItems
    self.applicationActivities = applicationActivities
  }
}
```
