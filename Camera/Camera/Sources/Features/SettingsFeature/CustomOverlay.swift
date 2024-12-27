import SwiftUI
import SwiftUINavigation

struct BottomMenuModifier<BottomMenuContent>: ViewModifier
where BottomMenuContent: View {
  @Binding var isActive: Bool
  let content: () -> BottomMenuContent
  
  func body(content: Content) -> some View {
    content.overlay(
      Group {
        if isActive {
          self.content()
        }
      }
    )
  }
}

extension View {
  func bottomMenu<Content>(
    isActive: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View
  where Content: View {
    modifier(
      BottomMenuModifier(
        isActive: isActive,
        content: content
      )
    )
  }
  
  func bottomMenu<Item, Content>(
    item: Binding<Item?>,
    @ViewBuilder content: @escaping (Binding<Item>) -> Content
  ) -> some View
  where Content: View {
    modifier(
      BottomMenuModifier(
        isActive: Binding(item),
        content: { Binding(unwrapping: item).map(content) }
      )
    )
  }
}

