import SwiftUI

struct GraphNode: Identifiable {
    let id: String          // note ID
    let title: String
    var position: CGPoint
    var velocity: CGPoint = .zero
    let linkCount: Int      // number of connections (for sizing)
}

struct GraphEdge: Identifiable {
    let id: String          // "sourceID-targetID"
    let sourceID: String
    let targetID: String
}

@MainActor
final class GraphViewModel: ObservableObject {
    @Published var nodes: [GraphNode] = []
    @Published var edges: [GraphEdge] = []
    @Published var isLoading = true
    @Published var selectedNodeID: String?

    private let noteRepo: NoteRepositoryProtocol
    private let linkRepo: LinkRepository
    private var simulationTimer: Timer?
    private let canvasSize: CGSize = CGSize(width: 1000, height: 1000)

    init(noteRepo: NoteRepositoryProtocol, linkRepo: LinkRepository) {
        self.noteRepo = noteRepo
        self.linkRepo = linkRepo
    }

    func load() async {
        isLoading = true
        do {
            let allNotes = try await noteRepo.fetchAll()

            // Build edges from link repository
            var allEdges: [GraphEdge] = []
            var linkCounts: [String: Int] = [:]  // noteID -> connection count
            var seenEdgeIDs: Set<String> = []

            for note in allNotes {
                let links = try linkRepo.fetchLinks(from: note.id)
                for link in links {
                    let edgeID = "\(link.sourceNoteID)-\(link.targetNoteID)"
                    guard !seenEdgeIDs.contains(edgeID) else { continue }
                    seenEdgeIDs.insert(edgeID)
                    allEdges.append(GraphEdge(id: edgeID, sourceID: link.sourceNoteID, targetID: link.targetNoteID))
                    linkCounts[link.sourceNoteID, default: 0] += 1
                    linkCounts[link.targetNoteID, default: 0] += 1
                }
            }

            // Create nodes with circular initial positions
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius: CGFloat = min(canvasSize.width, canvasSize.height) * 0.35

            nodes = allNotes.enumerated().map { index, note in
                let angle = (2 * .pi / CGFloat(max(allNotes.count, 1))) * CGFloat(index)
                let x = center.x + radius * cos(angle) + CGFloat.random(in: -20...20)
                let y = center.y + radius * sin(angle) + CGFloat.random(in: -20...20)

                return GraphNode(
                    id: note.id,
                    title: note.title.isEmpty ? "Untitled" : note.title,
                    position: CGPoint(x: x, y: y),
                    linkCount: linkCounts[note.id] ?? 0
                )
            }

            edges = allEdges
            isLoading = false

            startSimulation()

        } catch {
            isLoading = false
        }
    }

    func startSimulation() {
        var iterations = 0
        let maxIterations = 150

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }

            Task { @MainActor in
                self.simulationStep()
                iterations += 1
                if iterations >= maxIterations {
                    timer.invalidate()
                }
            }
        }
    }

    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    private func simulationStep() {
        guard nodes.count > 1 else { return }

        let repulsion: CGFloat = 5000
        let attraction: CGFloat = 0.01
        let damping: CGFloat = 0.9
        let idealDistance: CGFloat = 120
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let centerGravity: CGFloat = 0.01

        var forces = Array(repeating: CGPoint.zero, count: nodes.count)

        // Repulsion between all node pairs
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                let dx = nodes[i].position.x - nodes[j].position.x
                let dy = nodes[i].position.y - nodes[j].position.y
                let dist = max(sqrt(dx * dx + dy * dy), 1)
                let force = repulsion / (dist * dist)
                let fx = (dx / dist) * force
                let fy = (dy / dist) * force

                forces[i].x += fx
                forces[i].y += fy
                forces[j].x -= fx
                forces[j].y -= fy
            }
        }

        // Attraction along edges
        let nodeIndex = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($1.id, $0) })

        for edge in edges {
            guard let si = nodeIndex[edge.sourceID], let ti = nodeIndex[edge.targetID] else { continue }
            let dx = nodes[ti].position.x - nodes[si].position.x
            let dy = nodes[ti].position.y - nodes[si].position.y
            let dist = max(sqrt(dx * dx + dy * dy), 1)
            let force = (dist - idealDistance) * attraction
            let fx = (dx / dist) * force
            let fy = (dy / dist) * force

            forces[si].x += fx
            forces[si].y += fy
            forces[ti].x -= fx
            forces[ti].y -= fy
        }

        // Center gravity
        for i in 0..<nodes.count {
            let dx = center.x - nodes[i].position.x
            let dy = center.y - nodes[i].position.y
            forces[i].x += dx * centerGravity
            forces[i].y += dy * centerGravity
        }

        // Apply forces
        for i in 0..<nodes.count {
            nodes[i].velocity.x = (nodes[i].velocity.x + forces[i].x) * damping
            nodes[i].velocity.y = (nodes[i].velocity.y + forces[i].y) * damping

            let maxVel: CGFloat = 10
            nodes[i].velocity.x = max(-maxVel, min(maxVel, nodes[i].velocity.x))
            nodes[i].velocity.y = max(-maxVel, min(maxVel, nodes[i].velocity.y))

            nodes[i].position.x += nodes[i].velocity.x
            nodes[i].position.y += nodes[i].velocity.y
        }
    }

    func updateNodePosition(id: String, position: CGPoint) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index].position = position
            nodes[index].velocity = .zero
        }
    }
}
