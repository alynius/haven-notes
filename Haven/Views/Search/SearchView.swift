import SwiftUI

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            if viewModel.isSearching {
                ProgressView()
                    .tint(Color.havenPrimary)
            } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.havenTextSecondary.opacity(0.4))
                    Text("No results found")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } else if !viewModel.results.isEmpty {
                List {
                    ForEach(viewModel.results) { note in
                        Button {
                            appState.navigateTo(.noteEditor(noteID: note.id))
                        } label: {
                            SearchResultRowView(note: note)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query, prompt: "Search notes...")
        .onChange(of: viewModel.query) {
            viewModel.search()
        }
    }
}
