import Foundation
import IssueReporting
import LinkPresentation
import SwiftUI
import UIKit
import Dependencies

/// This is a SwiftUI MVVM abstraction over `UIKit.UIActivityViewController`,
/// because the default `SwiftUI.ShareButton` does not allow you to present the share sheet dynamically.
/// IE. You (suprisingly) cannot compute a URL and then display the share sheet in SwiftUI without dropping down to UIKit.
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

final class ActivityItem: UIActivityItemProvider, @unchecked Sendable {
  let url: URL
  
  init(url: URL) {
    self.url = url
    super.init(placeholderItem: url)
  }
  
  override func activityViewControllerLinkMetadata(
    _: UIActivityViewController
  ) -> LPLinkMetadata? {
    let metadata = LPLinkMetadata()
    metadata.url = url
    return metadata
  }
  
  override var item: Any {
    url
  }
}

// MARK: View

struct ActivityView: UIViewControllerRepresentable {
  @Bindable var model: ActivityModel
  
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(
      activityItems: self.model.activityItems,
      applicationActivities: self.model.applicationActivities
    )
  }
  
  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {
    uiViewController.completionWithItemsHandler = self.model.completionWithItemsHandler
  }
}

