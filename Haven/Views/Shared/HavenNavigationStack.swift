import SwiftUI

struct HavenNavigationStack: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var container: DependencyContainer

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            NoteListView(viewModel: NoteListViewModel(noteRepo: container.noteRepository))
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .noteEditor(let noteID):
                        noteEditorDestination(noteID: noteID)
                    case .search:
                        SearchView(viewModel: SearchViewModel(noteRepo: container.noteRepository))
                    case .settings:
                        SettingsView(viewModel: SettingsViewModel(noteRepo: container.noteRepository, db: container.databaseManager))
                    case .syncSettings:
                        SyncSettingsView(viewModel: SyncSettingsViewModel(syncManager: container.syncManager))
                    case .subscription:
                        SubscriptionView(viewModel: SubscriptionViewModel(subscriptionManager: container.subscriptionManager))
                    }
                }
        }
        .tint(Color.havenPrimary)
    }

    @ViewBuilder
    private func noteEditorDestination(noteID: String?) -> some View {
        if let noteID = noteID {
            NoteEditorView.forExisting(
                noteID: noteID,
                noteRepo: container.noteRepository,
                taskRepo: container.taskRepository,
                wikiLinkParser: container.wikiLinkParser
            )
        } else {
            NoteEditorView.forNew(
                noteRepo: container.noteRepository,
                taskRepo: container.taskRepository,
                wikiLinkParser: container.wikiLinkParser
            )
        }
    }
}
