import SwiftUI

/// Palette of named colors users can apply to folders.
private let folderColorPalette: [(name: String, hex: String)] = [
    ("Red", "#E74C3C"),
    ("Orange", "#F97316"),
    ("Yellow", "#F2C94C"),
    ("Green", "#42BD8C"),
    ("Blue", "#3B82F6"),
    ("Purple", "#A855F7"),
]

struct SidebarView: View {
    @StateObject var viewModel: SidebarViewModel
    @Environment(AppState.self) var appState
    @EnvironmentObject var container: DependencyContainer

    @State private var renamingFolderID: String?
    @State private var renameFolderText = ""

    private func folderTint(for folder: Folder) -> Color {
        if let hex = folder.color, let color = Color(hex: hex) {
            return color
        }
        return Color.havenPrimary
    }

    var body: some View {
        List(selection: Binding(
            get: { appState.activeFilter },
            set: { if let f = $0 { appState.activeFilter = f } }
        )) {
            // Daily Note
            Section {
                Button {
                    Task {
                        if let noteID = try? await container.dailyNoteService.getOrCreateDailyNote() {
                            appState.navigateTo(.noteEditor(noteID: noteID))
                        }
                    }
                } label: {
                    Label {
                        Text("Today's Note")
                            .font(.havenBody)
                    } icon: {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(Color.havenAccent)
                    }
                }
                .accessibilityIdentifier("sidebar_button_dailyNote")
            }

            // All Notes
            Section {
                Label {
                    HStack {
                        Text("All Notes")
                            .font(.havenBody)
                        Spacer()
                        Text("\(viewModel.totalNoteCount)")
                            .font(.havenCaption)
                            .foregroundColor(Color.havenTextSecondary)
                    }
                } icon: {
                    Image(systemName: "note.text")
                        .foregroundColor(Color.havenPrimary)
                }
                .tag(NoteFilter.allNotes)
                .accessibilityIdentifier("sidebar_row_allNotes")
            }

            // Folders
            Section {
                ForEach(viewModel.folders) { folder in
                    if renamingFolderID == folder.id {
                        HStack {
                            TextField("Folder name", text: $renameFolderText)
                                .font(.havenBody)
                                .onSubmit {
                                    Task {
                                        await viewModel.renameFolder(id: folder.id, name: renameFolderText)
                                        renamingFolderID = nil
                                    }
                                }
                            Button {
                                Task {
                                    await viewModel.renameFolder(id: folder.id, name: renameFolderText)
                                    renamingFolderID = nil
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.havenAccent)
                            }
                            Button {
                                renamingFolderID = nil
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(Color.havenTextSecondary)
                            }
                        }
                    } else {
                        Label {
                            HStack {
                                Text(folder.name)
                                    .font(.havenBody)
                                Spacer()
                                Text("\(viewModel.folderNoteCounts[folder.id] ?? 0)")
                                    .font(.havenCaption)
                                    .foregroundColor(Color.havenTextSecondary)
                            }
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(folderTint(for: folder))
                        }
                        .tag(NoteFilter.folder(id: folder.id, name: folder.name))
                        .contextMenu {
                            Button {
                                renamingFolderID = folder.id
                                renameFolderText = folder.name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Menu {
                                ForEach(folderColorPalette, id: \.hex) { swatch in
                                    Button {
                                        Task { await viewModel.setFolderColor(id: folder.id, color: swatch.hex) }
                                    } label: {
                                        Label(swatch.name, systemImage: "circle.fill")
                                            .foregroundColor(Color(hex: swatch.hex))
                                    }
                                }
                                Divider()
                                Button {
                                    Task { await viewModel.setFolderColor(id: folder.id, color: nil) }
                                } label: {
                                    Label("Default", systemImage: "circle")
                                }
                            } label: {
                                Label("Color", systemImage: "paintpalette")
                            }
                            Button(role: .destructive) {
                                Task { await viewModel.deleteFolder(id: folder.id) }
                            } label: {
                                Label("Delete Folder", systemImage: "trash")
                            }
                        }
                    }
                }
                .onMove { source, destination in
                    Task { await viewModel.reorderFolders(from: source, to: destination) }
                }

                if viewModel.isCreatingFolder {
                    HStack {
                        TextField("Folder name", text: $viewModel.newFolderName)
                            .font(.havenBody)
                            .accessibilityIdentifier("sidebar_textField_newFolderName")
                            .onSubmit {
                                Task { await viewModel.createFolder() }
                            }
                        Button {
                            Task { await viewModel.createFolder() }
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.havenAccent)
                        }
                        Button {
                            viewModel.isCreatingFolder = false
                            viewModel.newFolderName = ""
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(Color.havenTextSecondary)
                        }
                    }
                } else {
                    Button {
                        viewModel.isCreatingFolder = true
                    } label: {
                        Label("New Folder", systemImage: "plus")
                            .font(.havenBody)
                            .foregroundColor(Color.havenAccent)
                    }
                    .accessibilityIdentifier("sidebar_button_createFolder")
                }
            } header: {
                Text("Folders")
            }

            // Tags
            Section {
                if viewModel.tags.isEmpty {
                    Text("Add tags to notes to organize them")
                        .font(.havenCaption)
                        .foregroundColor(Color.havenTextSecondary)
                } else {
                    ForEach(viewModel.tags) { tag in
                        Label {
                            HStack {
                                Text(tag.name)
                                    .font(.havenBody)
                                Spacer()
                                Text("\(viewModel.tagNoteCounts[tag.id] ?? 0)")
                                    .font(.havenCaption)
                                    .foregroundColor(Color.havenTextSecondary)
                            }
                        } icon: {
                            Image(systemName: "tag")
                                .foregroundColor(Color.havenAccent)
                        }
                        .tag(NoteFilter.tag(id: tag.id, name: tag.name))
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteTag(id: tag.id) }
                            } label: {
                                Label("Delete Tag", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Tags")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Haven")
        .task {
            await viewModel.loadAll()
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
