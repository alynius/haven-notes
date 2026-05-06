import SwiftUI

struct NoteListView: View {
    @StateObject var viewModel: NoteListViewModel
    @Environment(AppState.self) var appState
    @EnvironmentObject var container: DependencyContainer
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var showDeleteConfirm = false
    @State private var noteToDelete: String?
    @State private var showSidebar = false
    @State private var isSelecting = false
    @State private var selectedNoteIDs: Set<String> = []

    private var navigationTitle: String {
        if isSelecting {
            return selectedNoteIDs.isEmpty ? "Select Notes" : "\(selectedNoteIDs.count) selected"
        }
        switch viewModel.filter {
        case .allNotes:
            return "All Notes"
        case .folder(_, let name):
            return name
        case .tag(_, let name):
            return "#\(name)"
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedNoteIDs.contains(id) {
            selectedNoteIDs.remove(id)
        } else {
            selectedNoteIDs.insert(id)
        }
    }

    private func exitSelectionMode() {
        isSelecting = false
        selectedNoteIDs = []
    }

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.notes.isEmpty {
                List {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonListRow()
                            .listRowBackground(Color.havenBackground)
                            .listRowSeparatorTint(Color.havenBorder)
                    }
                }
                .listStyle(.plain)
            } else if viewModel.notes.isEmpty {
                EmptyStateView(filter: viewModel.filter) {
                    Task {
                        if let id = await viewModel.createNote() {
                            appState.navigateTo(.noteEditor(noteID: id))
                        }
                    }
                }
            } else {
                List {
                    ForEach(viewModel.notes) { note in
                        Button {
                            if isSelecting {
                                toggleSelection(note.id)
                            } else {
                                appState.navigateTo(.noteEditor(noteID: note.id))
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                if isSelecting {
                                    Image(systemName: selectedNoteIDs.contains(note.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedNoteIDs.contains(note.id) ? Color.havenAccent : Color.havenTextSecondary.opacity(0.4))
                                        .accessibilityHidden(true)
                                }
                                NoteRowView(
                                    note: note,
                                    folderName: note.folderID.flatMap { viewModel.folders[$0] }
                                )
                                .hoverHighlight()
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("noteList_row_\(note.id)")
                        .listRowBackground(Color.havenBackground)
                        .listRowSeparatorTint(Color.havenBorder)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                noteToDelete = note.id
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .accessibilityHint("Deletes this note permanently")
                            .accessibilityIdentifier("noteList_button_delete_\(note.id)")
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task { await viewModel.togglePin(id: note.id) }
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                            }
                            .tint(Color.havenAccent)
                            .accessibilityIdentifier("noteList_button_pin_\(note.id)")
                        }
                        .contextMenu {
                            Button {
                                Task { await viewModel.togglePin(id: note.id) }
                            } label: {
                                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                            }

                            Menu {
                                if note.folderID != nil {
                                    Button {
                                        Task { await viewModel.moveNote(id: note.id, toFolderID: nil) }
                                    } label: {
                                        Label("No Folder", systemImage: "tray")
                                    }
                                    Divider()
                                }
                                ForEach(viewModel.folders.sorted(by: { $0.value.localizedCaseInsensitiveCompare($1.value) == .orderedAscending }), id: \.key) { folderID, folderName in
                                    if folderID != note.folderID {
                                        Button {
                                            Task { await viewModel.moveNote(id: note.id, toFolderID: folderID) }
                                        } label: {
                                            Label(folderName, systemImage: "folder")
                                        }
                                    }
                                }
                                if viewModel.folders.isEmpty && note.folderID == nil {
                                    Text("Create a folder in the sidebar first.")
                                }
                            } label: {
                                Label("Move to", systemImage: "folder")
                            }

                            Button(role: .destructive) {
                                noteToDelete = note.id
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { source, destination in
                        Task { await viewModel.reorderNotes(from: source, to: destination) }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadNotes()
                }
            }
        }
        .navigationTitle(navigationTitle)
        .sheet(isPresented: $showSidebar) {
            NavigationStack {
                SidebarView(viewModel: SidebarViewModel(
                    folderRepo: container.folderRepository,
                    tagRepo: container.tagRepository,
                    noteRepo: container.noteRepository
                ))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showSidebar = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: Spacing.md) {
                    if sizeClass != .regular {
                        Button { showSidebar = true } label: {
                            Image(systemName: "folder")
                                .foregroundColor(Color.havenPrimary)
                        }
                        .accessibilityLabel("Folders & Tags")
                        .accessibilityIdentifier("noteList_button_foldersAndTags")
                    }
                    Button { appState.navigateTo(.settings) } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color.havenPrimary)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("noteList_button_settings")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if isSelecting {
                        Menu {
                            Button {
                                Task {
                                    await viewModel.moveNotes(ids: selectedNoteIDs, toFolderID: nil)
                                    exitSelectionMode()
                                }
                            } label: {
                                Label("No Folder", systemImage: "tray")
                            }
                            Divider()
                            ForEach(viewModel.folders.sorted(by: { $0.value.localizedCaseInsensitiveCompare($1.value) == .orderedAscending }), id: \.key) { folderID, folderName in
                                Button {
                                    Task {
                                        await viewModel.moveNotes(ids: selectedNoteIDs, toFolderID: folderID)
                                        exitSelectionMode()
                                    }
                                } label: {
                                    Label(folderName, systemImage: "folder")
                                }
                            }
                        } label: {
                            Text("Move \(selectedNoteIDs.count)")
                                .foregroundColor(Color.havenPrimary)
                        }
                        .disabled(selectedNoteIDs.isEmpty || viewModel.folders.isEmpty)
                        .accessibilityIdentifier("noteList_button_bulkMove")
                        Button("Done") { exitSelectionMode() }
                            .foregroundColor(Color.havenPrimary)
                    } else {
                        Button {
                            isSelecting = true
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(Color.havenPrimary)
                        }
                        .accessibilityLabel("Select notes")
                        .accessibilityIdentifier("noteList_button_select")
                        Button { appState.navigateTo(.graph) } label: {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .foregroundColor(Color.havenPrimary)
                        }
                        .accessibilityLabel("Knowledge Graph")
                        .accessibilityIdentifier("noteList_button_graph")
                        Button { appState.navigateTo(.search) } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.havenPrimary)
                        }
                        .accessibilityLabel("Search")
                        .accessibilityIdentifier("noteList_button_search")
                        Button {
                            Task {
                                if let id = await viewModel.createNote() {
                                    appState.navigateTo(.noteEditor(noteID: id))
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color.havenPrimary)
                                .font(.title3)
                        }
                        .accessibilityLabel("New Note")
                        .accessibilityIdentifier("noteList_button_newNote")
                    }
                }
            }
            #elseif os(macOS)
            ToolbarItem(placement: .automatic) {
                HStack(spacing: Spacing.md) {
                    Button { appState.navigateTo(.settings) } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color.havenPrimary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 16) {
                    Button { appState.navigateTo(.graph) } label: {
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .foregroundColor(Color.havenPrimary)
                    }
                    .accessibilityLabel("Knowledge Graph")
                    Button { appState.navigateTo(.search) } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.havenPrimary)
                    }
                    .accessibilityLabel("Search")
                    Button {
                        Task {
                            if let id = await viewModel.createNote() {
                                appState.navigateTo(.noteEditor(noteID: id))
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.havenPrimary)
                            .font(.title3)
                    }
                    .accessibilityLabel("New Note")
                }
            }
            #endif
        }
        .confirmationDialog("Delete Note", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let id = noteToDelete {
                    Task { await viewModel.deleteNote(id: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This note will be moved to trash.")
        }
        .task {
            await viewModel.loadNotes()
        }
        .onChange(of: appState.activeFilter) { _, newFilter in
            viewModel.filter = newFilter
            showSidebar = false
            Task { await viewModel.loadNotes() }
        }
        .onChange(of: appState.navigationPath) { _, _ in
            showSidebar = false  // Dismiss sidebar when navigating (e.g. Daily Note)
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
}
