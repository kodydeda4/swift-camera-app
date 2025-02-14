# 📸 SwiftUI Camera App

A SwiftUI-based camera app with video recording, sharing, playback, and deletion functionalities.

Available on the [AppStore](https://apps.apple.com/us/app/idd-camera/id6740935223) now!

[![IDD Camera App Store Badge](https://github.com/user-attachments/assets/25ef15ca-5a73-447b-affa-a0b26a1d7082)](https://apps.apple.com/us/app/idd-camera/id6740935223)

<img width=150 src="https://github.com/user-attachments/assets/207232cf-12da-4d32-ad75-e1ba0f5a62e3">
<img width=150 src="https://github.com/user-attachments/assets/15cf6cc0-2df4-484e-a527-17ae201db80d">
<img width=150 src="https://github.com/user-attachments/assets/d3829880-bef3-4a55-a12e-b114ff95acbe">
<img width=150 src="https://github.com/user-attachments/assets/54690939-3156-4d8c-8bb7-ce0fba8c5c7f">
<img width=150 src="https://github.com/user-attachments/assets/d722a06d-521c-43ce-af6f-1ac311c69acc">

### 🛠️ Tech Stack
**SwiftUI:** For building the user interface.
**AVFoundation:** For camera and video recording functionalities.
**Swift-Concurrency:** For reactive programming and handling data flow.
**MVVM:** Application architecture.
**UIKit:** Lightweight integrations with existing UIKit views.

## User Permissions

The [swift-sharing](https://github.com/pointfreeco/swift-sharing) library makes it possible to easily preview the app in different states - such as when a user is missing specific permissions.

<img width="1500" alt="image" src="https://github.com/user-attachments/assets/e29a06fa-600d-467c-980c-08e9431d6c55" />

## Camera

[AVCaptureVideoPreviewLayer](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer) allows you to connect the camera to the UI. The app uses compiler directives to let you preview the camera directly in SwiftUI previews.

<img width="1200" alt="image" src="https://github.com/user-attachments/assets/816bdabe-12e4-417a-b384-e8cf3d465545" />

## Countdown

[Swift structured concurrency
](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) is used to create a timer that increments every second.  [Swift-issue-reporting](https://github.com/pointfreeco/swift-issue-reporting) is used to provide an unimplemented closure to execute once the timer is finished.

<img width="1200" alt="image" src="https://github.com/user-attachments/assets/cf2b96b0-2c42-4d24-99ef-a42c38019343" />

## Settings

A custom [swift-navigation](https://github.com/pointfreeco/swift-navigation) view-modifier was created to drive the overlay thru a binding.

<img width="1200" alt="image" src="https://github.com/user-attachments/assets/b4915f2a-56d6-4504-8f2d-0ce59e2e45bf" />

## Library

[PhotoKit](https://developer.apple.com/documentation/photokit) allows you to work with image & video assets that the photos app mangages. `Main` model listens for changes and caches them to shared state, for the `Library` feature to observe.

<!-- <img src="https://github.com/user-attachments/assets/c30ad8ba-0c65-473f-9bfe-44c460edf9b8" width="200" style="object-fit: contain; display: block; margin: auto;">    -->

```swift
final class MainModel {
  ...
  func task() async {
    await withThrowingTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        let photosContext = try await self.fetchOrCreateAssetCollection(
          withTitle: PhotosContext.title
        )
        await MainActor.run {
          self.$photosContext.assetCollection.withLock {
            $0 = photosContext
          }
        }
        for await fetchResult in await self.photos.streamAssets(
          .videos(in: photosContext)
        ) {
          await self.syncVideos(with: fetchResult)
        }
      }
    }
  }
```

## Video Player

`VideoPlayer` model allows you to handle all the logic for the video player.

<!-- <img src="https://github.com/user-attachments/assets/34d6dfe5-b118-4847-bb49-daf0661b14bb" width="200" style="object-fit: contain; display: block; margin: auto;">    -->

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

## Share

[UIActivityViewController](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller) allows you to present the share sheet dynamically, such as when a user taps a button. A [SwiftUI view modifier ](https://github.com/kodydeda4/swift-share-link) was created to let you model the destination without dropping down to UIKit.

<!-- <img src="https://github.com/user-attachments/assets/7602daa1-dd5f-43f2-aebe-c32c741e3032" width="200" style="object-fit: contain; display: block; margin: auto;"> -->

```swift
@MainActor
@Observable
final class ActivityModel: Identifiable {
  let id: UUID
  let activityItems: [UIActivityItemProvider]
  let applicationActivities: [UIActivity]
  var completionWithItemsHandler: UIActivityViewController
    .CompletionWithItemsHandler
}
```

