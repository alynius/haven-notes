import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct QuickCaptureEntry: TimelineEntry {
    let date: Date
    let noteCount: Int
}

// MARK: - Timeline Provider

struct QuickCaptureProvider: TimelineProvider {
    private static let appGroupID = "group.com.havennotes.app"
    private static let noteCountKey = "noteCount"

    private var sharedNoteCount: Int {
        UserDefaults(suiteName: Self.appGroupID)?.integer(forKey: Self.noteCountKey) ?? 0
    }

    func placeholder(in context: Context) -> QuickCaptureEntry {
        QuickCaptureEntry(date: Date(), noteCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickCaptureEntry) -> Void) {
        completion(QuickCaptureEntry(date: Date(), noteCount: sharedNoteCount))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCaptureEntry>) -> Void) {
        let entry = QuickCaptureEntry(date: Date(), noteCount: sharedNoteCount)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

// MARK: - Haven Brand Colors

private enum HavenColors {
    static let gradientStart = Color(red: 0x9B / 255, green: 0x7F / 255, blue: 0x57 / 255)
    static let gradientEnd = Color(red: 0x7A / 255, green: 0x5F / 255, blue: 0x38 / 255)

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Small Widget (Tap to create new note)

struct QuickCaptureSmallView: View {
    let entry: QuickCaptureEntry

    var body: some View {
        ZStack {
            HavenColors.brandGradient

            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white)

                Text("Quick Note")
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundColor(.white)

                if entry.noteCount > 0 {
                    Text("\(entry.noteCount) notes")
                        .font(.system(.caption2, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .widgetURL(URL(string: "haven://new-note"))
    }
}

// MARK: - Medium Widget (New Note + Daily Note side by side)

struct QuickCaptureMediumView: View {
    let entry: QuickCaptureEntry

    var body: some View {
        ZStack {
            HavenColors.brandGradient

            HStack(spacing: 16) {
                Link(destination: URL(string: "haven://new-note")!) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .light))
                        Text("New Note")
                            .font(.system(.caption, design: .serif).weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 50)

                Link(destination: URL(string: "haven://daily-note")!) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 28, weight: .light))
                        Text("Daily Note")
                            .font(.system(.caption, design: .serif).weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Lock Screen Widgets

struct QuickCaptureLockScreenCircularView: View {
    let entry: QuickCaptureEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
        .widgetURL(URL(string: "haven://new-note"))
    }
}

struct QuickCaptureLockScreenRectangularView: View {
    let entry: QuickCaptureEntry

    var body: some View {
        Label("Quick Note", systemImage: "note.text.badge.plus")
            .font(.system(.body, design: .serif))
            .widgetURL(URL(string: "haven://new-note"))
    }
}

// MARK: - Widget Configuration

@main
struct HavenWidget: Widget {
    let kind: String = "HavenQuickCapture"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickCaptureProvider()) { entry in
            if #available(iOS 17.0, *) {
                widgetView(for: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                widgetView(for: entry)
            }
        }
        .configurationDisplayName("Quick Capture")
        .description("Instantly create a new note in Haven.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }

    @ViewBuilder
    private func widgetView(for entry: QuickCaptureEntry) -> some View {
        HavenWidgetEntryView(entry: entry)
    }
}

// MARK: - Entry View (reads widget family from environment)

private struct HavenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: QuickCaptureEntry

    var body: some View {
        switch family {
        case .systemSmall:
            QuickCaptureSmallView(entry: entry)
        case .systemMedium:
            QuickCaptureMediumView(entry: entry)
        case .accessoryCircular:
            QuickCaptureLockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            QuickCaptureLockScreenRectangularView(entry: entry)
        default:
            QuickCaptureSmallView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    HavenWidget()
} timeline: {
    QuickCaptureEntry(date: Date(), noteCount: 5)
}

#Preview("Medium", as: .systemMedium) {
    HavenWidget()
} timeline: {
    QuickCaptureEntry(date: Date(), noteCount: 5)
}
