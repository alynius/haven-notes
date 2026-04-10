import SwiftUI

struct TaskListView: View {
    let tasks: [NoteTask]
    let onToggle: (String) -> Void
    let onDelete: (String) -> Void
    var onAdd: ((String) -> Void)? = nil
    var onReorder: (([String]) -> Void)? = nil

    @State private var newTaskText = ""
    @FocusState private var isNewTaskFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tasks")
                .font(.havenCaption)
                .foregroundColor(Color.havenTextSecondary)
                .padding(.bottom, 4)

            ForEach(tasks) { task in
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onToggle(task.id)
                        }
                    } label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(task.isCompleted ? Color.havenAccent : Color.havenTextSecondary.opacity(0.5))
                    }
                    .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
                    .accessibilityIdentifier("taskList_button_toggle_\(task.id)")

                    Text(task.text)
                        .font(.havenContentBody)
                        .foregroundColor(task.isCompleted ? Color.havenTextSecondary : Color.havenTextPrimary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)

                    Spacer()

                    Button { onDelete(task.id) } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(Color.havenTextSecondary.opacity(0.4))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("taskList_button_delete_\(task.id)")
                }
                .padding(.vertical, 6)
            }

            // Add new task
            if onAdd != nil {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(Color.havenTextSecondary.opacity(0.4))

                    TextField("Add a task...", text: $newTaskText)
                        .font(.havenContentBody)
                        .foregroundColor(Color.havenTextPrimary)
                        .focused($isNewTaskFocused)
                        .accessibilityIdentifier("taskList_textField_newTask")
                        .onSubmit {
                            submitNewTask()
                        }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func submitNewTask() {
        let text = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onAdd?(text)
        newTaskText = ""
        isNewTaskFocused = true
    }
}
