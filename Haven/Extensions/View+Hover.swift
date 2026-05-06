import SwiftUI

private struct HoverHighlight: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Color.havenSurface : Color.clear)
            }
            .onHover { hovering in
                withAnimation(.havenSnappy) {
                    isHovering = hovering
                }
            }
    }
}

extension View {
    /// Adds a subtle background tint while a pointer hovers the view.
    /// No-ops on touch-only devices since `.onHover` never fires there.
    func hoverHighlight() -> some View {
        modifier(HoverHighlight())
    }
}
