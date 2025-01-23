# 📸 SwiftUI Camera App

A SwiftUI-based camera app with video recording, sharing, playback, and deletion functionalities.

<img width=185 src="https://github.com/user-attachments/assets/53de5b6e-cadc-494e-89b7-6bde399ffcd1">
<img width=185 src="https://github.com/user-attachments/assets/b2a6cef6-feb2-4b86-af2a-bc39689377e7">
<img width=185 src="https://github.com/user-attachments/assets/4424ec3d-146d-4736-bbca-78b87168f61e">
<img width=185 src="https://github.com/user-attachments/assets/38a60968-b48f-4d03-bedc-fe91b935b8c3">
<img width=185 src="https://github.com/user-attachments/assets/ae0ee5b6-886c-4571-a9ea-bdfc36cd72f7">

## 🚀 Features

- 🎥 **Video Recording**: Record high-quality videos directly within the app.
- 🌐 **Sharing**: Easily share videos to your friends using Apple's built-in Activity feature.
- ▶️ **Playback**: Enjoy a built-in video player to view your recorded content.
- 🗑️ **Deletion**: Manage your video library with the ability to delete unwanted recordings.

## 🛠️ Tech Stack
- **SwiftUI**: For building the user interface
- **AVFoundation**: For camera and video recording functionalities.
- **Swift-Concurrency**: For reactive programming and handling data flow.
- **MVVM**: Application architecture
- **UIKit**: Lightweight integrations with existing UIKit views.

### 🧰 Dependencies
This app was built using various libraries from [PointFree](https://www.pointfree.co/).
- [swift-dependenices](https://github.com/pointfreeco/swift-dependencies): A dependency management library inspired by SwiftUI's "environment."
- [swift-navigation](https://github.com/pointfreeco/swift-navigation): Bringing simple and powerful navigation tools to all Swift platforms, inspired by SwiftUI.
- [swift-sharing](https://github.com/pointfreeco/swift-sharing): Instantly share state among your app's features and external persistence layers, including user defaults, the file system, and more.

## 🏠 Architecture

The app follows an MVVM architecture.

### Features

Features are organized as a tree - where each major view is powered by a model.

```mermaid
%%{init: {'flowchart': {'curve': 'linear'}, 'themeVariables': {'nodeWidth': 150, 'nodeSpacing': 50, 'rankSpacing': 50}} }%%
flowchart LR
    A(App) --> C(Onboarding)
    A(App) -->B(Main)
    C --> D(UserPermissions)
    B --> E(Camera)
    E --> K(UserPermissions)
    F --> G(VideoPlayer)
    G --> H(Activity)
    E --> I(Countdown)
    E --> J(Settings)
    E --> F(Library)
    
    
```

### Dependencies

Dependenices are global, self-contained, and non-heirarchical.

```mermaid
%%{init: {'flowchart': {'curve': 'linear'}, 'themeVariables': {'nodeWidth': 150, 'nodeSpacing': 50, 'rankSpacing': 50}} }%%
flowchart TD
    A(Dependencies)
    A --> E(Camera)
    A --> H(PhotoLibrary)
    A --> B(Application)
    A --> D(Audio)
    A --> F(HapticFeedback)
    A --> G(ImageGenerator)
```
