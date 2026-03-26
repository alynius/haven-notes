import SwiftUI

struct NoteListView: View {
    @StateObject var viewModel: NoteListViewModel
    @EnvironmentObject var appState: AppState
    @State private var showDeleteConfirm = false
    @State private var noteToDelete: String?

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            if viewModel.notes.isEmpty && !viewModel.isLoading {
                EmptyStateView()
            } else {
                List {
                    ForEach(viewModel.notes) { note in
                        Button {
                            appState.navigateTo(.noteEditor(noteID: note.id))
                        } label: {
                            NoteRowView(note: note)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.havenBackground)
                        .listRowSeparatorTint(Color.havenBorder)
                        .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    noteToDelete = note.id
                                    showDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task { await viewModel.togglePin(id: note.id) }
                                } label: {
                                    Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(Color.havenAccent)
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadNotes()
                }
            }
        }
        .navigationTitle("Haven")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { appState.navigateTo(.settings) } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.havenPrimary)
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button { appState.navigateTo(.search) } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.havenPrimary)
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
                            .foregroundStyle(.havenPrimary)
                            .font(.title3)
                    }
                    .accessibilityLabel("New Note")
                }
            }
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
