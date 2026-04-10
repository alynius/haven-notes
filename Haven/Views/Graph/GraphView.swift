import SwiftUI

struct GraphView: View {
    @StateObject var viewModel: GraphViewModel
    @EnvironmentObject var appState: AppState

    @State private var scale: CGFloat = 0.5
    @State private var lastScale: CGFloat = 0.5
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var draggedNodeID: String?

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("Building graph...")
                    .font(.havenBody)
                    .foregroundColor(Color.havenTextSecondary)
            } else if viewModel.nodes.isEmpty {
                emptyState
            } else {
                graphContent
            }
        }
        .navigationTitle("Graph")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .onDisappear {
            viewModel.stopSimulation()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.havenPrimary.opacity(0.4))
                .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.3))
            Text("No connections yet")
                .font(.havenHeadline)
                .foregroundColor(Color.havenTextPrimary)
            Text("Link notes with [[wiki links]] to see your knowledge graph")
                .font(.havenBody)
                .foregroundColor(Color.havenTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
    }

    // MARK: - Graph Content

    private var graphContent: some View {
        ZStack {
            graphCanvas
                .scaleEffect(scale)
                .offset(offset)
                .gesture(panGesture)
                .gesture(zoomGesture)

            // Stats badge + Reset zoom
            VStack {
                Spacer()
                HStack {
                    Text("\(viewModel.nodes.count) notes \u{00B7} \(viewModel.edges.count) links")
                        .font(.havenCaption)
                        .foregroundColor(Color.havenTextSecondary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .accessibilityIdentifier("graph_badge_stats")
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            scale = 0.5
                            lastScale = 0.5
                            offset = .zero
                            lastOffset = .zero
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.havenCaption)
                            .foregroundColor(Color.havenTextSecondary)
                            .padding(Spacing.sm)
                            .background(.regularMaterial)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Reset zoom")
                    .accessibilityIdentifier("graph_button_resetZoom")
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - Canvas

    private var graphCanvas: some View {
        // Canvas + node overlays are in the same coordinate space,
        // both transformed together by scaleEffect and offset.
        ZStack {
            Canvas { context, _ in
                // Draw edges
                for edge in viewModel.edges {
                    guard let sourceNode = viewModel.nodes.first(where: { $0.id == edge.sourceID }),
                          let targetNode = viewModel.nodes.first(where: { $0.id == edge.targetID }) else { continue }

                    var path = Path()
                    path.move(to: sourceNode.position)
                    path.addLine(to: targetNode.position)

                    context.stroke(path, with: .color(Color.havenBorder), lineWidth: 1)
                }

                // Draw nodes
                for node in viewModel.nodes {
                    let nodeSize = nodeSize(for: node)
                    let rect = CGRect(
                        x: node.position.x - nodeSize / 2,
                        y: node.position.y - nodeSize / 2,
                        width: nodeSize,
                        height: nodeSize
                    )

                    let isSelected = node.id == viewModel.selectedNodeID
                    let fillColor = isSelected ? Color.havenAccent : Color.havenPrimary

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(fillColor.opacity(0.85))
                    )

                    // Node label
                    let labelPoint = CGPoint(x: node.position.x, y: node.position.y + nodeSize / 2 + 10)
                    context.draw(
                        Text(node.title)
                            .font(.system(size: 10))
                            .foregroundColor(Color.havenTextPrimary),
                        at: labelPoint
                    )
                }
            }

            // Node hit targets — same coordinate space as the canvas
            ForEach(viewModel.nodes) { node in
                let size = max(44, nodeSize(for: node))

                Circle()
                    .fill(Color.clear)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
                    .position(node.position)
                    .accessibilityLabel("\(node.title), \(node.linkCount) links")
                    .onTapGesture {
                        viewModel.selectedNodeID = node.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            appState.navigateTo(.noteEditor(noteID: node.id))
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                draggedNodeID = node.id
                                // Convert drag location from transformed to canvas coordinates
                                let canvasPos = CGPoint(
                                    x: (value.location.x - offset.width) / scale,
                                    y: (value.location.y - offset.height) / scale
                                )
                                viewModel.updateNodePosition(id: node.id, position: canvasPos)
                            }
                            .onEnded { _ in
                                draggedNodeID = nil
                            }
                    )
            }
        }
        .frame(width: 1000, height: 1000)
    }

    // MARK: - Gestures

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard draggedNodeID == nil else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(0.2, min(3.0, lastScale * value))
            }
            .onEnded { value in
                scale = max(0.2, min(3.0, lastScale * value))
                lastScale = scale
            }
    }

    // MARK: - Helpers

    private func nodeSize(for node: GraphNode) -> CGFloat {
        CGFloat(max(24, min(48, 24 + node.linkCount * 6)))
    }
}
