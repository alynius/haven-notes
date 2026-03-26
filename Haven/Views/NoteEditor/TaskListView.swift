import SwiftUI

struct TaskListView: View {
    let tasks: [NoteTask]
    let onToggle: (String) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tasks")
                .font(.havenCaption)
                .foregroundStyle(.havenTextSecondary)
                .padding(.bottom, 4)

            ForEach(tasks) { task in
                HStack(spacing: 12) {
                    Button { onToggle(task.id) } label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(task.isCompleted ? .havenAccent : .havenTextSecondary.opacity(0.5))
                    }

                    Text(task.text)
                        .font(.havenContentBody)
                        .foregroundStyle(task.isCompleted ? .havenTextSecondary : .havenTextPrimary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)

                    Spacer()

                    Button { onDelete(task.id) } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(Color.havenTextSecondary.opacity(0.4))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
}
