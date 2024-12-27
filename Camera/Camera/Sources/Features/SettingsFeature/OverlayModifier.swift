import SwiftUI
import SwiftUINavigation

struct OverlayModifier<OverlayModifier>: ViewModifier
where OverlayModifier: View {
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
  func overlay<Content>(
    isActive: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View
  where Content: View {
    modifier(
      OverlayModifier(
        isActive: isActive,
        content: content
      )
    )
  }
  
  func overlay<Item, Content>(
    item: Binding<Item?>,
    @ViewBuilder content: @escaping (Binding<Item>) -> Content
  ) -> some View
  where Content: View {
    modifier(
      OverlayModifier(
        isActive: Binding(item),
        content: { Binding(unwrapping: item).map(content) }
      )
    )
  }
}

