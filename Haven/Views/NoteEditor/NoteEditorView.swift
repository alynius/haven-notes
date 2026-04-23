import SwiftUI

struct NoteEditorView: View {
    @StateObject var viewModel: NoteEditorViewModel
    @EnvironmentObject var appState: AppState
    @FocusState private var titleFocused: Bool

    /// Shared reference to the editor coordinator for toolbar actions.
    #if os(iOS)
    @StateObject private var editorShared = RichTextEditor.Shared()
    #elseif os(macOS)
    @StateObject private var editorShared = MacEditorView.Shared()
    #endif

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    TextField("Untitled", text: Binding(
                        get: { viewModel.note.title },
                        set: { viewModel.updateTitle($0) }
                    ))
                    .font(.havenContentTitle)
                    .foregroundColor(Color.havenTextPrimary)
                    .focused($titleFocused)
                    .accessibilityIdentifier("noteEditor_textField_title")
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.sm)

                    // Subtle warm divider
                    Rectangle()
                        .fill(Color.havenBorder.opacity(0.6))
                        .frame(height: 0.5)

                    // Body editor
                    #if os(iOS)
                    RichTextEditor(
                        htmlContent: Binding(
                            get: { viewModel.note.bodyHTML },
                            set: { viewModel.updateBody($0) }
                        ),
                        onLinkTapped: { target in
                            Task {
                                if let linked = await viewModel.resolveWikiLink(title: target) {
                                    appState.navigateTo(.noteEditor(noteID: linked.id))
                                }
                            }
                        },
                        shared: editorShared
                    )
                    .frame(minHeight: 300)
                    #elseif os(macOS)
                    MacEditorView(
                        htmlContent: Binding(
                            get: { viewModel.note.bodyHTML },
                            set: { viewModel.updateBody($0) }
                        ),
                        onLinkTapped: { target in
                            Task {
                                if let linked = await viewModel.resolveWikiLink(title: target) {
                                    appState.navigateTo(.noteEditor(noteID: linked.id))
                                }
                            }
                        },
                        onTextChanged: { _ in },
                        shared: editorShared
                    )
                    .frame(minHeight: 300)
                    #endif

                    // Tags section
                    if viewModel.isLoaded {
                        TagPickerView(
                            tags: viewModel.tags,
                            allTags: viewModel.allTags,
                            onAdd: { name in Task { await viewModel.addTag(name: name) } },
                            onRemove: { tagID in Task { await viewModel.removeTag(tagID: tagID) } }
                        )
                    }

                    // Tasks section
                    TaskListView(
                        tasks: viewModel.tasks,
                        onToggle: { id in Task { await viewModel.toggleTask(id) } },
                        onDelete: { id in Task { await viewModel.deleteTask(id) } },
                        onAdd: { text in Task { await viewModel.addTask(text: text) } }
                    )
                    .padding(.top, 12)

                    // Backlinks section
                    if !viewModel.backlinks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Linked from")
                                .font(.havenCaption)
                                .foregroundColor(Color.havenTextSecondary)
                                .accessibilityAddTraits(.isHeader)

                            ForEach(viewModel.backlinks) { linked in
                                Button {
                                    appState.navigateTo(.noteEditor(noteID: linked.id))
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.turn.up.left")
                                            .font(.caption)
                                        Text(linked.title.isEmpty ? "Untitled" : linked.title)
                                            .font(.havenBody)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(Color.havenAccent)
                                }
                                .accessibilityLabel("Linked from \(linked.title.isEmpty ? "Untitled" : linked.title)")
                            }
                        }
                        .padding(.top, 20)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            #if os(iOS)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    // Dictation banner
                    if viewModel.speechRecognizer.isRecording {
                        HStack(spacing: Spacing.sm) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text(viewModel.speechRecognizer.transcript.isEmpty ? "Listening..." : viewModel.speechRecognizer.transcript)
                                .font(.havenCaption)
                                .foregroundColor(Color.havenTextPrimary)
                                .lineLimit(2)
                            Spacer()
                            Button("Insert") {
                                viewModel.insertDictatedText(viewModel.speechRecognizer.transcript)
                                viewModel.speechRecognizer.stopRecording()
                            }
                            .font(.havenCaption.weight(.semibold))
                            .foregroundColor(Color.havenAccent)
                            .disabled(viewModel.speechRecognizer.transcript.isEmpty)
                            .accessibilityIdentifier("noteEditor_button_insertDictation")
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.havenSurface)
                    }

                    EditorToolbarView(
                        onBold: { editorShared.coordinator?.insertBold() },
                        onItalic: { editorShared.coordinator?.insertItalic() },
                        onHeading: { editorShared.coordinator?.insertHeading(level: 1) },
                        onList: { editorShared.coordinator?.insertList() },
                        onCheckbox: { editorShared.coordinator?.insertCheckbox() },
                        onLink: { editorShared.coordinator?.insertLink() },
                        onMicrophone: {
                            Task {
                                await viewModel.speechRecognizer.toggleRecording()
                            }
                        },
                        isRecording: viewModel.speechRecognizer.isRecording,
                        activeFormats: editorShared.activeFormats
                    )
                }
            }
            #endif

            // Autocomplete overlay
            if viewModel.showAutocomplete {
                WikiLinkAutocompleteView(
                    suggestions: viewModel.autocompleteSuggestions,
                    onSelect: { note in
                        viewModel.selectAutocompleteSuggestion(note)
                        // Update the text view to reflect the inserted link
                        #if os(iOS)
                        if let coordinator = editorShared.coordinator {
                            coordinator.applyHighlighting(to: coordinator.textView!, text: viewModel.note.bodyHTML)
                        }
                        #elseif os(macOS)
                        if let coordinator = editorShared.coordinator,
                           let textView = coordinator.textView {
                            coordinator.applyHighlighting(to: textView, text: viewModel.note.bodyHTML)
                        }
                        #endif
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showAutocomplete)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Spacing.md) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(Color.havenPrimary)
                    }
                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .foregroundColor(Color.havenPrimary)
                    }
                    .accessibilityLabel("Dismiss keyboard")
                    .accessibilityIdentifier("noteEditor_button_dismissKeyboard")
                }
            }
            #elseif os(macOS)
            ToolbarItem {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(Color.havenPrimary)
                }
            }
            #endif
        }
        .task {
            await viewModel.load()
            if viewModel.note.title.isEmpty && viewModel.note.bodyHTML.isEmpty {
                titleFocused = true
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Factory methods

    static func forExisting(noteID: String, noteRepo: NoteRepositoryProtocol, taskRepo: TaskRepositoryProtocol, tagRepo: TagRepositoryProtocol, wikiLinkParser: WikiLinkParser) -> NoteEditorView {
        let note = Note(id: noteID)
        let vm = NoteEditorViewModel(note: note, noteRepo: noteRepo, taskRepo: taskRepo, tagRepo: tagRepo, wikiLinkParser: wikiLinkParser)
        return NoteEditorView(viewModel: vm)
    }

    static func forNew(noteRepo: NoteRepositoryProtocol, taskRepo: TaskRepositoryProtocol, tagRepo: TagRepositoryProtocol, wikiLinkParser: WikiLinkParser) -> NoteEditorView {
        let note = Note()
        let vm = NoteEditorViewModel(note: note, noteRepo: noteRepo, taskRepo: taskRepo, tagRepo: tagRepo, wikiLinkParser: wikiLinkParser)
        return NoteEditorView(viewModel: vm)
    }
}
