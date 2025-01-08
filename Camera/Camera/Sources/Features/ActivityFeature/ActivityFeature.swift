import Foundation
import IssueReporting
import LinkPresentation
import SwiftUI
import UIKit

/// This is a SwiftUI MVVM abstraction over `UIKit.UIActivityViewController`, addressing the limitations of `SwiftUI.ShareButton`.
/// Specifically, this code was created so that you can present a share sheet after computing a URL.

@MainActor
@Observable
final class ActivityModel: Identifiable {
  let id: UUID
  let activityItems: [ActivityItem]
  let applicationActivities: [UIActivity]
  var completionWithItemsHandler: UIActivityViewController
    .CompletionWithItemsHandler = unimplemented("ActivityModel.completionWithItemsHandler")

  init(
    id: UUID,
    activityItems: [ActivityItem],
    applicationActivities: [UIActivity] = []
  ) {
    self.id = id
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

