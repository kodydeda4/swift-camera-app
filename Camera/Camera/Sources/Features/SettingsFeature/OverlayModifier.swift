import SwiftUI
import SwiftUINavigation

private struct OverlayModifier<OverlayModifier>: ViewModifier
  where OverlayModifier: View
{
  @Binding var isActive: Bool
  let content: () -> OverlayModifier

  func body(content: Content) -> some View {
    content.overlay {
      if isActive {
        self.content()
      }
    }
  }
}

extension View {
  /// Layers the views that you specify in front of this view,
  /// when the binding to a Boolean value you provide is true.
  func overlay<Content>(
    isActive: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View
    where Content: View
  {
    modifier(
      OverlayModifier(
        isActive: isActive,
        content: content
      )
    )
  }

  /// Layers the views that you specify in front of this view,
  /// using the binding you provide as a data source for the overlay’s content
  func overlay<Item, Content>(
    item: Binding<Item?>,
    @ViewBuilder content: @escaping (Binding<Item>) -> Content
  ) -> some View
    where Content: View
  {
    modifier(
      OverlayModifier(
        isActive: Binding(item),
        content: { Binding(unwrapping: item).map(content) }
      )
    )
  }
}

