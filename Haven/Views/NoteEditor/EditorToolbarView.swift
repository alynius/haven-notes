#if os(iOS)
import SwiftUI

struct EditorToolbarView: View {
    var onBold: () -> Void = {}
    var onItalic: () -> Void = {}
    var onHeading: () -> Void = {}
    var onList: () -> Void = {}
    var onCheckbox: () -> Void = {}
    var onLink: () -> Void = {}
    var onMicrophone: () -> Void = {}
    var isRecording: Bool = false
    var activeFormats: Set<MarkdownFormat> = []

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                toolbarButton("bold", label: "Bold", isActive: activeFormats.contains(.bold), action: onBold)
                    .accessibilityIdentifier("editorToolbar_button_bold")
                toolbarButton("italic", label: "Italic", isActive: activeFormats.contains(.italic), action: onItalic)
                    .accessibilityIdentifier("editorToolbar_button_italic")
                toolbarButton("textformat.size", label: "Heading", isActive: activeFormats.contains(.heading), action: onHeading)
                    .accessibilityIdentifier("editorToolbar_button_heading")
                toolbarButton("list.bullet", label: "List", isActive: activeFormats.contains(.list), action: onList)
                    .accessibilityIdentifier("editorToolbar_button_list")
                toolbarButton("checkmark.square", label: "Checkbox", action: onCheckbox)
                    .accessibilityIdentifier("editorToolbar_button_checkbox")
                toolbarButton("link", label: "Link", action: onLink)
                    .accessibilityIdentifier("editorToolbar_button_link")
                toolbarButton(
                    isRecording ? "mic.fill" : "mic",
                    label: isRecording ? "Stop dictation" : "Start dictation",
                    action: onMicrophone
                )
                .accessibilityIdentifier("editorToolbar_button_microphone")
                .foregroundColor(isRecording ? Color.red : Color.havenTextPrimary)
                .overlay(
                    isRecording
                        ? Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .offset(x: 12, y: -12)
                        : nil
                )
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

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private func toolbarButton(_ systemName: String, label: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            haptic.impactOccurred()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.callout.weight(.medium))
                .foregroundColor(isActive ? Color.havenAccent : Color.havenTextPrimary)
                .frame(width: 44, height: 44)
                .background(isActive ? Color.havenAccent.opacity(0.12) : Color.havenBackground)
                .clipShape(.rect(cornerRadius: 6))
        }
        .buttonStyle(ToolbarPressStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// Scale-down press effect for toolbar buttons.
private struct ToolbarPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect((!reduceMotion && configuration.isPressed) ? 0.9 : 1.0)
            .animation(reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
#endif
