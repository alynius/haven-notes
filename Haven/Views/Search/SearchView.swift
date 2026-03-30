import SwiftUI

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            if viewModel.query.isEmpty && viewModel.results.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(Color.havenTextSecondary.opacity(0.3))
                    Text("Search your notes")
                        .font(.havenBody)
                        .foregroundColor(Color.havenTextSecondary)
                }
            } else if viewModel.isSearching {
                List {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonListRow()
                            .listRowBackground(Color.havenBackground)
                    }
                }
                .listStyle(.plain)
            } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(Color.havenTextSecondary.opacity(0.4))
                    Text("No results found")
                        .font(.havenBody)
                        .foregroundStyle(.secondary)
                    Text("Try a different search term")
                        .font(.havenCaption)
                        .foregroundColor(Color.havenTextSecondary)
                    Button {
                        viewModel.query = ""
                    } label: {
                        Text("Clear Search")
                            .font(.havenBody.weight(.medium))
                            .foregroundColor(Color.havenPrimary)
                    }
                    .padding(.top, Spacing.xs)
                }
            } else if !viewModel.results.isEmpty {
                List {
                    ForEach(viewModel.results) { note in
                        Button {
                            appState.navigateTo(.noteEditor(noteID: note.id))
                        } label: {
                            SearchResultRowView(note: note, query: viewModel.query)
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
        .onChange(of: viewModel.query) { _ in
            viewModel.search()
        }
    }
}
