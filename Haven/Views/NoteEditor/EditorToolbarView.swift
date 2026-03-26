import SwiftUI

struct EditorToolbarView: View {
    var onBold: () -> Void = {}
    var onItalic: () -> Void = {}
    var onHeading: () -> Void = {}
    var onList: () -> Void = {}
    var onCheckbox: () -> Void = {}
    var onLink: () -> Void = {}

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                toolbarButton("bold", action: onBold)
                toolbarButton("italic", action: onItalic)
                toolbarButton("textformat.size", action: onHeading)
                toolbarButton("list.bullet", action: onList)
                toolbarButton("checkmark.square", action: onCheckbox)
                toolbarButton("link", action: onLink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.havenSurface)
        .overlay(
            Divider().background(Color.havenBorder),
            alignment: .top
        )
    }

    private func toolbarButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.callout.weight(.medium))
                .foregroundStyle(.havenTextPrimary)
                .frame(width: 44, height: 44)
                .background(Color.havenBackground)
                .clipShape(.rect(cornerRadius: 6))
        }
    }
}
