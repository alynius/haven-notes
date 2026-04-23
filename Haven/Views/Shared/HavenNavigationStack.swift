import SwiftUI
#if os(macOS)
import AppKit
#endif

struct HavenNavigationStack: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var container: DependencyContainer
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if sizeClass == .regular {
                    // iPad: Split view with sidebar
                    NavigationSplitView {
                        SidebarView(viewModel: SidebarViewModel(
                            folderRepo: container.folderRepository,
                            tagRepo: container.tagRepository,
                            noteRepo: container.noteRepository
                        ))
                    } detail: {
                        navigationContent
                    }
                } else {
                    // iPhone: Plain NavigationStack (no sidebar gesture delay)
                    navigationContent
                }
            }
            .tint(Color.havenPrimary)
            .onChange(of: appState.pendingAction) { action in
                guard action != .none else { return }
                Task {
                    switch action {
                    case .openDailyNote:
                        let service = DailyNoteService(noteRepo: container.noteRepository)
                        if let noteID = try? await service.getOrCreateDailyNote() {
                            appState.navigationPath = NavigationPath()
                            appState.navigateTo(.noteEditor(noteID: noteID))
                        }
                    case .none:
                        break
                    }
                    appState.pendingAction = .none
                }
            }
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: .havenNewNote)) { _ in
                appState.navigateTo(.noteEditor(noteID: nil))
            }
            .onReceive(NotificationCenter.default.publisher(for: .havenDailyNote)) { _ in
                appState.pendingAction = .openDailyNote
            }
            .onReceive(NotificationCenter.default.publisher(for: .havenSearch)) { _ in
                appState.navigateTo(.search)
            }
            .onReceive(NotificationCenter.default.publisher(for: .havenShowGraph)) { _ in
                appState.navigateTo(.graph)
            }
            #endif

            // Global toast overlay
            if let toast = toastManager.currentToast {
                ToastView(
                    message: toast.message,
                    icon: toast.icon,
                    type: toast.type
                )
                .padding(.top, Spacing.huge)
                .zIndex(100)
            }
        }
    }

    private var navigationContent: some View {
        NavigationStack(path: $appState.navigationPath) {
            NoteListView(viewModel: NoteListViewModel(
                noteRepo: container.noteRepository,
                folderRepo: container.folderRepository,
                filter: appState.activeFilter
            ))
            #if os(macOS)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        NSApp.keyWindow?.firstResponder?.tryToPerform(
                            #selector(NSSplitViewController.toggleSidebar(_:)),
                            with: nil
                        )
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
            #endif
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
                case .encryption:
                    EncryptionSettingsView()
                case .notionImport:
                    NotionImportView(importer: container.notionImporter)
                case .graph:
                    GraphView(viewModel: GraphViewModel(
                        noteRepo: container.noteRepository,
                        linkRepo: container.linkRepository
                    ))
                }
            }
        }
    }

    @ViewBuilder
    private func noteEditorDestination(noteID: String?) -> some View {
        if let noteID = noteID {
            NoteEditorView.forExisting(
                noteID: noteID,
                noteRepo: container.noteRepository,
                taskRepo: container.taskRepository,
                tagRepo: container.tagRepository,
                wikiLinkParser: container.wikiLinkParser
            )
        } else {
            NoteEditorView.forNew(
                noteRepo: container.noteRepository,
                taskRepo: container.taskRepository,
                tagRepo: container.tagRepository,
                wikiLinkParser: container.wikiLinkParser
            )
        }
    }
}
