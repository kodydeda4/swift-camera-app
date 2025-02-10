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

The [swift-sharing](https://github.com/pointfreeco/swift-sharing) library makes it possible to easily preview the app in different states - such as missing permissions, and easily observe state across features.

<img width="1500" alt="image" src="https://github.com/user-attachments/assets/e29a06fa-600d-467c-980c-08e9431d6c55" />

### Camera

[AVFoundation](https://developer.apple.com/av-foundation/).[AVCaptureVideoPreviewLayer](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer) allows you to connect the camera to the UI layer. The app also uses compiler directives to let you preview the camera using an image for SwiftUI previews.

<img width="1200" alt="image" src="https://github.com/user-attachments/assets/816bdabe-12e4-417a-b384-e8cf3d465545" />

### Countdown

[Swift structured concurrency 
](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) is used to create a timer, and [swift-issue-reporting](https://github.com/pointfreeco/swift-issue-reporting) allows you to provide `unimplemented` closures

<img width="1200" alt="image" src="https://github.com/user-attachments/assets/cf2b96b0-2c42-4d24-99ef-a42c38019343" />

### Settings

A custom view-modifier was created using [swift-navigation](https://github.com/pointfreeco/swift-navigation), to drive the overlay thru a binding to the `SettingsModel`.

<img width="1200" alt="image" src="https://github.com/user-attachments/assets/b4915f2a-56d6-4504-8f2d-0ce59e2e45bf" />

```swift
extension View {
  /// Layers the views that you specify in front of this view,
  /// when the binding to a Boolean value you provide is true.
  func overlay<Content>(
    isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View
    where Content: View
  {
    modifier(
      OverlayModifier(
        isPresented: isPresented,
        content: content
      )
    )
  }

```

### Library

[PhotoKit](https://developer.apple.com/documentation/photokit) allows you to work with image & video assets that the photos app mangages. `Main` model listens for changes and caches them to shared state, for the `Library` feature to observe.

<table>
<tr>
<th>
Preview
</th>
<th>
Code
</th>
</tr>

<tr>

<td>
<img width=250 src="https://github.com/user-attachments/assets/c30ad8ba-0c65-473f-9bfe-44c460edf9b8">  
</td>

<td>

```swift
final class MainModel {
  ...
  @ObservationIgnored @Shared(.photosContext) var photosContext
  @ObservationIgnored @Dependency(\.photos) var photos
  @ObservationIgnored @Dependency(\.uuid) var uuid
  @ObservationIgnored @Dependency(\.imageGenerator) var imageGenerator
  
  func task() async {
    await withThrowingTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        let photosContext = try await self.fetchOrCreateAssetCollection(
          withTitle: PhotosContext.title
        )
        await MainActor.run {
          self.$photosContext.assetCollection.withLock { $0 = photosContext }
        }
        for await fetchResult in await self.photos.streamAssets(.videos(in: photosContext)) {
          await self.syncVideos(with: fetchResult)
        }
      }
    }
  }
```

</td>
</table>

#### Video Player

`VideoPlayer` model allows you to handle all the logic for the video player.

<table>
<tr>
<th>
Preview
</th>
<th>
Code
</th>
</tr>

<tr>

<td>
<img width=250 src="https://github.com/user-attachments/assets/34d6dfe5-b118-4847-bb49-daf0661b14bb">  
</td>

<td>

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

</td>
</table>

#### Share

SwiftUI MVVM abstraction over [UIKit.UIActivityViewController](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller) allows you to present the share sheet dynamically.

<table>
<tr>
<th>
Preview
</th>
<th>
Code
</th>
</tr>

<tr>

<td>
<img width=250 src="https://github.com/user-attachments/assets/7602daa1-dd5f-43f2-aebe-c32c741e3032">
</td>

<td>

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

</td>
</table>
