import SwiftUI

struct NoteListView: View {
    @StateObject var viewModel: NoteListViewModel
    @Environment(AppState.self) var appState
    @EnvironmentObject var container: DependencyContainer
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var showDeleteConfirm = false
    @State private var noteToDelete: String?
    @State private var showSidebar = false
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    @State private var selectedNoteIDs: Set<String> = []

    private var isEditing: Bool { editMode == .active }
    #else
    private var isEditing: Bool { false }
    #endif

    private var navigationTitle: String {
        #if os(iOS)
        if isEditing && !selectedNoteIDs.isEmpty {
            return "\(selectedNoteIDs.count) selected"
        }
        #endif
        switch viewModel.filter {
        case .allNotes:
            return "All Notes"
        case .folder(_, let name):
            return name
        case .tag(_, let name):
            return "#\(name)"
        }
    }

    #if os(iOS)
    private func toggleSelection(_ id: String) {
        if selectedNoteIDs.contains(id) {
            selectedNoteIDs.remove(id)
        } else {
            selectedNoteIDs.insert(id)
        }
    }

    private func exitEditMode() {
        editMode = .inactive
        selectedNoteIDs = []
    }
    #endif

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
                            #if os(iOS)
                            if isEditing {
                                toggleSelection(note.id)
                                return
                            }
                            #endif
                            appState.navigateTo(.noteEditor(noteID: note.id))
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                #if os(iOS)
                                if isEditing {
                                    Image(systemName: selectedNoteIDs.contains(note.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedNoteIDs.contains(note.id) ? Color.havenAccent : Color.havenTextSecondary.opacity(0.4))
                                        .accessibilityHidden(true)
                                }
                                #endif
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
                    if isEditing {
                        Menu {
                            Button {
                                Task {
                                    await viewModel.moveNotes(ids: selectedNoteIDs, toFolderID: nil)
                                    exitEditMode()
                                }
                            } label: {
                                Label("No Folder", systemImage: "tray")
                            }
                            Divider()
                            ForEach(viewModel.folders.sorted(by: { $0.value.localizedCaseInsensitiveCompare($1.value) == .orderedAscending }), id: \.key) { folderID, folderName in
                                Button {
                                    Task {
                                        await viewModel.moveNotes(ids: selectedNoteIDs, toFolderID: folderID)
                                        exitEditMode()
                                    }
                                } label: {
                                    Label(folderName, systemImage: "folder")
                                }
                            }
                        } label: {
                            Text(selectedNoteIDs.isEmpty ? "Move" : "Move \(selectedNoteIDs.count)")
                                .foregroundColor(Color.havenPrimary)
                        }
                        .disabled(selectedNoteIDs.isEmpty || viewModel.folders.isEmpty)
                        .accessibilityIdentifier("noteList_button_bulkMove")
                        EditButton()
                            .foregroundColor(Color.havenPrimary)
                            .accessibilityIdentifier("noteList_button_edit")
                    } else {
                        #if os(iOS)
                        EditButton()
                            .foregroundColor(Color.havenPrimary)
                            .accessibilityIdentifier("noteList_button_edit")
                        #endif
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
        #if os(iOS)
        .environment(\.editMode, $editMode)
        .onChange(of: editMode) { _, new in
            if new != .active { selectedNoteIDs = [] }
        }
        #endif
        .task {
            await viewModel.loadNotes()
        }
        .onChange(of: appState.activeFilter) { _, newFilter in
            viewModel.filter = newFilter
            showSidebar = false
            #if os(iOS)
            exitEditMode()
            #endif
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
