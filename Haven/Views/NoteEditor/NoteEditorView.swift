import SwiftUI

struct NoteEditorView: View {
    @StateObject var viewModel: NoteEditorViewModel
    @EnvironmentObject var appState: AppState
    @FocusState private var titleFocused: Bool

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
                    .foregroundStyle(.havenTextPrimary)
                    .focused($titleFocused)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    Divider()
                        .background(Color.havenBorder)
                        .padding(.horizontal, 16)

                    // Body editor
                    RichTextEditor(
                        htmlContent: Binding(
                            get: { viewModel.note.bodyHTML },
                            set: { viewModel.updateBody($0) }
                        ),
                        onLinkTapped: { target in
                            Task {
                                if let linked = try? await viewModel.noteRepo.resolveWikiLink(title: target) {
                                    appState.navigateTo(.noteEditor(noteID: linked.id))
                                }
                            }
                        }
                    )
                    .frame(minHeight: 300)
                    .padding(.horizontal, 4)

                    // Tasks section
                    if !viewModel.tasks.isEmpty {
                        TaskListView(
                            tasks: viewModel.tasks,
                            onToggle: { id in Task { await viewModel.toggleTask(id) } },
                            onDelete: { id in Task { await viewModel.deleteTask(id) } }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    // Backlinks section
                    if !viewModel.backlinks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Linked from")
                                .font(.havenCaption)
                                .foregroundStyle(.havenTextSecondary)

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
                                    .foregroundStyle(.havenAccent)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }

                    Spacer(minLength: 100)
                }
            }

            // Autocomplete overlay
            if viewModel.showAutocomplete {
                WikiLinkAutocompleteView(
                    suggestions: viewModel.autocompleteSuggestions,
                    onSelect: { note in
                        viewModel.selectAutocompleteSuggestion(note)
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(Color.havenPrimary)
                }
            }
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

    static func forExisting(noteID: String, noteRepo: NoteRepositoryProtocol, taskRepo: TaskRepositoryProtocol, wikiLinkParser: WikiLinkParser) -> NoteEditorView {
        // Load note synchronously for now — will be replaced with async loading
        let note = Note(id: noteID)
        let vm = NoteEditorViewModel(note: note, noteRepo: noteRepo, taskRepo: taskRepo, wikiLinkParser: wikiLinkParser)
        return NoteEditorView(viewModel: vm)
    }

    static func forNew(noteRepo: NoteRepositoryProtocol, taskRepo: TaskRepositoryProtocol, wikiLinkParser: WikiLinkParser) -> NoteEditorView {
        let note = Note()
        let vm = NoteEditorViewModel(note: note, noteRepo: noteRepo, taskRepo: taskRepo, wikiLinkParser: wikiLinkParser)
        return NoteEditorView(viewModel: vm)
    }
}
