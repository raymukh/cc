import SwiftUI
import Combine
import Charts

// MARK: - Application entry point
@available(iOS 16.0, macOS 13.0, *)
@main
struct ProjectPulseApp: App {
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            DashboardContainerView()
                .environmentObject(dataController)
                .task { await dataController.bootstrap() }
        }
    }
}

// MARK: - Data controller
@MainActor
final class DataController: ObservableObject {
    @Published private(set) var summary: CompanySummary = .placeholder
    @Published private(set) var projects: [Project] = []
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var activity: [ActivityEvent] = []

    private let persistence = LocalPersistence()

    func bootstrap() async {
        do {
            let snapshot = try await persistence.loadSnapshot()
            apply(snapshot: snapshot)
        } catch {
            print("Failed to load snapshot: \(error)")
            apply(snapshot: .placeholder)
        }
    }

    func refresh() async {
        await bootstrap()
    }

    func toggleTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        persistence.persist(tasks: tasks)
    }

    func addQuickNote(_ note: ActivityEvent.Note) {
        let event = ActivityEvent(id: UUID(), title: "Note added", timestamp: .now, kind: .note(note))
        activity.insert(event, at: 0)
        persistence.persist(activity: activity)
    }

    func apply(snapshot: DataSnapshot) {
        summary = snapshot.summary
        projects = snapshot.projects.sorted { $0.updatedAt > $1.updatedAt }
        tasks = snapshot.tasks.sorted { $0.dueDate < $1.dueDate }
        activity = snapshot.activity.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Persistence
struct DataSnapshot: Codable {
    var summary: CompanySummary
    var projects: [Project]
    var tasks: [TaskItem]
    var activity: [ActivityEvent]

    static let placeholder = DataSnapshot(
        summary: .placeholder,
        projects: SampleData.projects,
        tasks: SampleData.tasks,
        activity: SampleData.activity
    )
}

actor LocalPersistence {
    private let url: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        url = directory?.appending(path: "project-pulse.json") ?? URL(fileURLWithPath: "/tmp/project-pulse.json")
    }

    func loadSnapshot() async throws -> DataSnapshot {
        if FileManager.default.fileExists(atPath: url.path()) {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(DataSnapshot.self, from: data)
        } else {
            let snapshot = DataSnapshot.placeholder
            try persist(snapshot: snapshot)
            return snapshot
        }
    }

    func persist(tasks: [TaskItem]) {
        Task { await persistPartial { snapshot in snapshot.tasks = tasks } }
    }

    func persist(activity: [ActivityEvent]) {
        Task { await persistPartial { snapshot in snapshot.activity = activity } }
    }

    private func persist(snapshot: DataSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    private func persistPartial(_ update: @escaping (inout DataSnapshot) -> Void) async {
        do {
            var snapshot = try await loadSnapshot()
            update(&snapshot)
            try persist(snapshot: snapshot)
        } catch {
            print("Failed to persist snapshot: \(error)")
        }
    }
}

// MARK: - Models
struct CompanySummary: Codable, Equatable {
    var activeProjects: Int
    var overdueTasks: Int
    var satisfaction: Double
    var revenueByMonth: [MonthlyRevenue]

    struct MonthlyRevenue: Codable, Identifiable, Equatable {
        var id: UUID = .init()
        var month: String
        var value: Double
    }

    static let placeholder = CompanySummary(
        activeProjects: 4,
        overdueTasks: 2,
        satisfaction: 0.86,
        revenueByMonth: [
            MonthlyRevenue(month: "Jan", value: 120_000),
            MonthlyRevenue(month: "Feb", value: 118_500),
            MonthlyRevenue(month: "Mar", value: 134_250),
            MonthlyRevenue(month: "Apr", value: 142_100),
            MonthlyRevenue(month: "May", value: 156_750)
        ]
    )
}

struct Project: Codable, Identifiable, Hashable {
    enum Status: String, Codable, CaseIterable, Identifiable {
        case discovery, planning, inProgress, blocked, complete

        var id: String { rawValue }

        var tint: Color {
            switch self {
            case .discovery: return .mint
            case .planning: return .indigo
            case .inProgress: return .blue
            case .blocked: return .orange
            case .complete: return .green
            }
        }

        var label: String {
            switch self {
            case .discovery: return "Discovery"
            case .planning: return "Planning"
            case .inProgress: return "In Progress"
            case .blocked: return "Blocked"
            case .complete: return "Complete"
            }
        }
    }

    var id: UUID
    var name: String
    var summary: String
    var status: Status
    var updatedAt: Date
    var owner: TeamMember
}

struct TeamMember: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var role: String
}

struct TaskItem: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var project: ProjectReference

    struct ProjectReference: Codable, Hashable {
        var id: UUID
        var name: String
    }
}

struct ActivityEvent: Codable, Identifiable, Hashable {
    enum Kind: Codable, Hashable {
        case milestone(String)
        case note(Note)
        case task(TaskItem)

        enum CodingKeys: CodingKey { case milestone, note, task }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let milestone = try container.decodeIfPresent(String.self, forKey: .milestone) {
                self = .milestone(milestone)
            } else if let note = try container.decodeIfPresent(Note.self, forKey: .note) {
                self = .note(note)
            } else if let task = try container.decodeIfPresent(TaskItem.self, forKey: .task) {
                self = .task(task)
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unknown ActivityEvent kind"))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .milestone(let value):
                try container.encode(value, forKey: .milestone)
            case .note(let note):
                try container.encode(note, forKey: .note)
            case .task(let task):
                try container.encode(task, forKey: .task)
            }
        }
    }

    struct Note: Codable, Hashable {
        var author: TeamMember
        var message: String
    }

    var id: UUID
    var title: String
    var timestamp: Date
    var kind: Kind
}

// MARK: - Views
@available(iOS 16.0, macOS 13.0, *)
struct DashboardContainerView: View {
    @EnvironmentObject private var data: DataController
    @State private var isRefreshing = false
    @State private var showingQuickNote = false
    @State private var quickNote = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SummaryHeader(summary: data.summary)
                    RevenueChart(revenue: data.summary.revenueByMonth)
                    ProjectsSection(projects: data.projects)
                    TaskSection(tasks: data.tasks, toggleTask: data.toggleTask)
                    ActivityFeedSection(activity: data.activity)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("Project Pulse")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingQuickNote = true
                    } label: {
                        Label("Quick Note", systemImage: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Button {
                            Task { await refresh() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingQuickNote) {
                QuickNoteSheet(noteText: $quickNote) { message in
                    let author = SampleData.team.randomElement() ?? SampleData.team[0]
                    let note = ActivityEvent.Note(author: author, message: message)
                    data.addQuickNote(note)
                }
            }
        }
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        await data.refresh()
        isRefreshing = false
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SummaryHeader: View {
    let summary: CompanySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                MetricTile(title: "Active Projects", value: "\(summary.activeProjects)", systemImage: "folder.fill")
                MetricTile(title: "Overdue Tasks", value: "\(summary.overdueTasks)", systemImage: "exclamationmark.triangle.fill", tint: .orange)
                MetricTile(title: "Satisfaction", value: summary.satisfaction.percentDisplay, systemImage: "hand.thumbsup.fill", tint: .green)
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct MetricTile: View {
    var title: String
    var value: String
    var systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.largeTitle.bold())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct RevenueChart: View {
    let revenue: [CompanySummary.MonthlyRevenue]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Revenue")
                .font(.title2.bold())
            Chart(revenue) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Revenue", item.value)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 220)
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ProjectsSection: View {
    let projects: [Project]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Projects")
                .font(.title2.bold())
            ForEach(projects) { project in
                NavigationLink(value: project) {
                    ProjectCard(project: project)
                }
            }
        }
        .navigationDestination(for: Project.self) { project in
            ProjectDetailView(project: project)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: project.status)
            }
            Text(project.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label(project.owner.name, systemImage: "person.fill")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(project.updatedAt, format: .relative(presentation: .named))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct StatusBadge: View {
    let status: Project.Status

    var body: some View {
        Text(status.label.uppercased())
            .font(.caption.bold())
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(status.tint.opacity(0.15))
            .foregroundStyle(status.tint)
            .clipShape(Capsule())
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ProjectDetailView: View {
    let project: Project

    var body: some View {
        List {
            Section("Summary") {
                Text(project.summary)
            }
            Section("Owner") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.owner.name).font(.headline)
                    Text(project.owner.role).foregroundStyle(.secondary)
                }
            }
            Section("Status") {
                StatusBadge(status: project.status)
            }
        }
        .navigationTitle(project.name)
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct TaskSection: View {
    let tasks: [TaskItem]
    var toggleTask: (TaskItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Tasks")
                .font(.title2.bold())
            ForEach(tasks) { task in
                TaskRow(task: task) { toggleTask(task) }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct TaskRow: View {
    let task: TaskItem
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    Text("Due \(task.dueDate, style: .date) • \(task.project.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ActivityFeedSection: View {
    let activity: [ActivityEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.title2.bold())
            ForEach(activity) { event in
                ActivityRow(event: event)
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ActivityRow: View {
    let event: ActivityEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title).font(.headline)
                Spacer()
                Text(event.timestamp, format: .relative(presentation: .numeric))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            switch event.kind {
            case .milestone(let message):
                Label(message, systemImage: "flag.fill")
                    .foregroundStyle(.blue)
            case .note(let note):
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.message)
                    Text("— \(note.author.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .task(let task):
                Label("Task \(task.isCompleted ? "completed" : "updated"): \(task.title)", systemImage: "checkmark.seal")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct QuickNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var noteText: String
    var onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("New note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Quick Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSubmit(trimmed)
                        noteText = ""
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sample data
enum SampleData {
    static let team: [TeamMember] = [
        TeamMember(id: UUID(), name: "Samira Lee", role: "Product Manager"),
        TeamMember(id: UUID(), name: "Nikhil Rao", role: "iOS Engineer"),
        TeamMember(id: UUID(), name: "Adriana Flores", role: "Design Lead"),
        TeamMember(id: UUID(), name: "Liam Chen", role: "Backend Engineer")
    ]

    static let projects: [Project] = [
        Project(
            id: UUID(),
            name: "Discovery Hub",
            summary: "Next-generation research workflow for distributed teams.",
            status: .inProgress,
            updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            owner: team[0]
        ),
        Project(
            id: UUID(),
            name: "Pulse Analytics",
            summary: "Unified dashboard with predictive health indicators.",
            status: .planning,
            updatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
            owner: team[1]
        ),
        Project(
            id: UUID(),
            name: "LaunchPad",
            summary: "Automation toolkit for onboarding enterprise customers.",
            status: .discovery,
            updatedAt: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now,
            owner: team[2]
        )
    ]

    static let tasks: [TaskItem] = [
        TaskItem(
            id: UUID(),
            title: "Finalize analytics schema",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
            isCompleted: false,
            project: .init(id: projects[1].id, name: projects[1].name)
        ),
        TaskItem(
            id: UUID(),
            title: "Storyboard onboarding flow",
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
            isCompleted: false,
            project: .init(id: projects[2].id, name: projects[2].name)
        ),
        TaskItem(
            id: UUID(),
            title: "Review discovery interview notes",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            isCompleted: true,
            project: .init(id: projects[0].id, name: projects[0].name)
        )
    ]

    static let activity: [ActivityEvent] = [
        ActivityEvent(
            id: UUID(),
            title: "LaunchPad milestone reached",
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now,
            kind: .milestone("Prototype approved by stakeholders")
        ),
        ActivityEvent(
            id: UUID(),
            title: "Discovery interview summary",
            timestamp: Calendar.current.date(byAdding: .hour, value: -5, to: .now) ?? .now,
            kind: .note(.init(author: team[0], message: "Key insight: teams need faster approvals."))
        ),
        ActivityEvent(
            id: UUID(),
            title: "Task completed",
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            kind: .task(tasks[2])
        )
    ]
}

// MARK: - Formatters
private enum Formatters {
    static let percent: Foundation.NumberFormatter = {
        let formatter = Foundation.NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

private extension Double {
    var percentDisplay: String {
        Formatters.percent.string(from: NSNumber(value: self)) ?? "--"
    }
}

// MARK: - Preview
@available(iOS 16.0, macOS 13.0, *)
struct DashboardContainerView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardContainerView()
            .environmentObject({
                let controller = DataController()
                controller.apply(snapshot: .placeholder)
                return controller
            }())
    }
}
