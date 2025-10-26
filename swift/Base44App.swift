import SwiftUI

// MARK: - Entry point
@available(iOS 16.0, macOS 13.0, *)
@main
struct BridgeAIApp: App {
    var body: some Scene {
        WindowGroup {
            BridgeAIDashboardScene()
        }
    }
}

// MARK: - Root scene
@available(iOS 16.0, macOS 13.0, *)
struct BridgeAIDashboardScene: View {
    @StateObject private var viewModel = DashboardViewModel.sample()

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(items: viewModel.sidebarItems, hotlines: viewModel.hotlines)
                .frame(width: 260)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 6, y: 0)

            Divider()
                .opacity(0.0)

            DashboardContentView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
        }
        .ignoresSafeArea(.all, edges: .vertical)
    }
}

// MARK: - Sidebar
@available(iOS 16.0, macOS 13.0, *)
struct SidebarView: View {
    let items: [SidebarItem]
    let hotlines: [Hotline]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Image(systemName: "shield.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.blue)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("BridgeAI")
                            .font(.title3.weight(.semibold))
                        Text("Every second matters")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    SidebarRow(item: item)
                }
            }

            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 12) {
                Text("Emergency Hotlines")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(hotlines) { hotline in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(hotline.label)
                                    .font(.footnote.weight(.medium))
                                Text(hotline.number)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "phone.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.blue)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SidebarRow: View {
    let item: SidebarItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 26, height: 26)
                .foregroundStyle(item.isActive ? Color.white : Color.blue)
                .background(
                    Circle()
                        .fill(item.isActive ? Color.blue : Color.blue.opacity(0.12))
                )

            Text(item.title)
                .font(.system(size: 16, weight: item.isActive ? .semibold : .regular))
                .foregroundStyle(item.isActive ? .primary : .secondary)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(item.isActive ? Color.blue.opacity(0.12) : Color.clear)
        )
    }
}

// MARK: - Main dashboard content
@available(iOS 16.0, macOS 13.0, *)
struct DashboardContentView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HeaderView(user: viewModel.user, readiness: viewModel.readiness)

                QuickActionsSection(actions: viewModel.quickActions)

                SafetyStatusSection(metrics: viewModel.safetyMetrics)

                VStack(spacing: 20) {
                    RecentActivityCard(activity: viewModel.recentActivity)
                    SafetyTipCard(tip: viewModel.dailyTip)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)
        }
    }
}

// MARK: - Header + readiness
@available(iOS 16.0, macOS 13.0, *)
struct HeaderView: View {
    let user: DashboardUser
    let readiness: EmergencyReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to \(user.displayName)")
                    .font(.system(size: 34, weight: .bold))
                Text("Your intelligent safety companion, ready when you need it most")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            EmergencyReadinessCard(readiness: readiness)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EmergencyReadinessCard: View {
    let readiness: EmergencyReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Emergency Readiness")
                        .font(.headline)
                    Text(readiness.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(readiness.scoreText)
                    .font(.title.weight(.bold))
                    .foregroundStyle(readiness.accent)
            }

            ProgressView(value: readiness.score)
                .tint(readiness.accent)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            Text(readiness.statusMessage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(readiness.accent)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(readiness.accent.opacity(0.1))
                )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 8)
        )
    }
}

// MARK: - Quick actions
@available(iOS 16.0, macOS 13.0, *)
struct QuickActionsSection: View {
    let actions: [QuickAction]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 3), spacing: 18) {
                ForEach(actions) { action in
                    QuickActionCard(action: action)
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct QuickActionCard: View {
    let action: QuickAction

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(action.title)
                        .font(.headline)
                    Text(action.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Spacer(minLength: 4)

            HStack(spacing: 8) {
                Text(action.ctaTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(action.tint)
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(action.tint)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(action.tint.opacity(0.25), lineWidth: action.isPrimary ? 2 : 1)
        )
    }
}

// MARK: - Safety status
@available(iOS 16.0, macOS 13.0, *)
struct SafetyStatusSection: View {
    let metrics: [SafetyMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Safety Status")
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(metrics) { metric in
                    SafetyMetricCard(metric: metric)
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SafetyMetricCard: View {
    let metric: SafetyMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(metric.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(metric.completed)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(metric.accent)
                Text("/ \(metric.total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(metric.actionLabel) {}
                .buttonStyle(PlainButtonStyle())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(metric.accent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(metric.accent.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 6)
    }
}

// MARK: - Activity + safety tip
@available(iOS 16.0, macOS 13.0, *)
struct RecentActivityCard: View {
    let activity: RecentActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Recent Activity")
                .font(.title3.weight(.semibold))

            HStack(alignment: .center, spacing: 20) {
                Circle()
                    .fill(activity.accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: activity.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(activity.accent)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.title)
                        .font(.headline)
                    Text(activity.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 8)
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SafetyTipCard: View {
    let tip: SafetyTip

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Safety Tip of the Day")
                .font(.title3.weight(.semibold))

            Text(tip.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: {}) {
                Text(tip.ctaTitle)
                    .font(.footnote.weight(.semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.blue.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 8)
        )
    }
}

// MARK: - View model & models
@available(iOS 16.0, macOS 13.0, *)
final class DashboardViewModel: ObservableObject {
    @Published var user: DashboardUser
    @Published var readiness: EmergencyReadiness
    @Published var quickActions: [QuickAction]
    @Published var safetyMetrics: [SafetyMetric]
    @Published var recentActivity: RecentActivity
    @Published var dailyTip: SafetyTip
    let sidebarItems: [SidebarItem]
    let hotlines: [Hotline]

    init(
        user: DashboardUser,
        readiness: EmergencyReadiness,
        quickActions: [QuickAction],
        safetyMetrics: [SafetyMetric],
        recentActivity: RecentActivity,
        dailyTip: SafetyTip,
        sidebarItems: [SidebarItem],
        hotlines: [Hotline]
    ) {
        self.user = user
        self.readiness = readiness
        self.quickActions = quickActions
        self.safetyMetrics = safetyMetrics
        self.recentActivity = recentActivity
        self.dailyTip = dailyTip
        self.sidebarItems = sidebarItems
        self.hotlines = hotlines
    }

    static func sample() -> DashboardViewModel {
        DashboardViewModel(
            user: DashboardUser(displayName: "BridgeAI"),
            readiness: EmergencyReadiness(
                score: 0.0,
                description: "Review personalized levels based on contacts, supplies, and emergency scenario",
                statusMessage: "Needs Work",
                accent: Color.red
            ),
            quickActions: [
                QuickAction(
                    title: "AI Assistant",
                    subtitle: "Get immediate guidance for any emergency",
                    ctaTitle: "Access Now",
                    tint: Color.blue
                ),
                QuickAction(
                    title: "Emergency SOS",
                    subtitle: "One-tap access to emergency services and contacts",
                    ctaTitle: "Access Now",
                    tint: Color.red,
                    isPrimary: true
                ),
                QuickAction(
                    title: "Preparedness Plans",
                    subtitle: "Review disaster plans and checklists for your household",
                    ctaTitle: "Access Now",
                    tint: Color.indigo
                )
            ],
            safetyMetrics: [
                SafetyMetric(title: "Emergency Contacts", completed: 0, total: 3, accent: Color.blue, actionLabel: "Manage"),
                SafetyMetric(title: "Supply Readiness", completed: 0, total: 3, accent: Color.orange, actionLabel: "Manage"),
                SafetyMetric(title: "Courses Completed", completed: 0, total: 4, accent: Color.green, actionLabel: "Manage"),
                SafetyMetric(title: "Drill Practices", completed: 0, total: 2, accent: Color.purple, actionLabel: "Review")
            ],
            recentActivity: RecentActivity(
                title: "All Clear",
                message: "No recent emergency activity. Stay prepared!",
                icon: "checkmark.seal.fill",
                accent: Color.green
            ),
            dailyTip: SafetyTip(
                message: "Keep your emergency contacts updated. Make sure all contact information is current, and share your notification settings regularly to stay connected.",
                ctaTitle: "Review Contacts"
            ),
            sidebarItems: [
                SidebarItem(title: "Dashboard", icon: "house.fill", isActive: true),
                SidebarItem(title: "AI Assistant", icon: "wand.and.sparkles", isActive: false),
                SidebarItem(title: "Emergency", icon: "bell.fill", isActive: false),
                SidebarItem(title: "Preparedness", icon: "shield.lefthalf.fill", isActive: false),
                SidebarItem(title: "Courses", icon: "book.closed.fill", isActive: false),
                SidebarItem(title: "Contacts", icon: "person.2.fill", isActive: false)
            ],
            hotlines: [
                Hotline(label: "911", number: "Emergency"),
                Hotline(label: "988", number: "Crisis Lifeline"),
                Hotline(label: "311", number: "City Services")
            ]
        )
    }
}

struct DashboardUser {
    var displayName: String
}

struct EmergencyReadiness {
    var score: Double // 0.0 – 1.0
    var description: String
    var statusMessage: String
    var accent: Color

    var scoreText: String {
        "\(Int(score * 100))%"
    }
}

struct QuickAction: Identifiable {
    var id: UUID = .init()
    var title: String
    var subtitle: String
    var ctaTitle: String
    var tint: Color
    var isPrimary: Bool = false
}

struct SafetyMetric: Identifiable {
    var id: UUID = .init()
    var title: String
    var completed: Int
    var total: Int
    var accent: Color
    var actionLabel: String
}

struct RecentActivity {
    var title: String
    var message: String
    var icon: String
    var accent: Color
}

struct SafetyTip {
    var message: String
    var ctaTitle: String
}

struct SidebarItem: Identifiable {
    var id: UUID = .init()
    var title: String
    var icon: String
    var isActive: Bool
}

struct Hotline: Identifiable {
    var id: UUID = .init()
    var label: String
    var number: String
}

// MARK: - Preview
@available(iOS 16.0, macOS 13.0, *)
struct BridgeAIDashboardScene_Previews: PreviewProvider {
    static var previews: some View {
        BridgeAIDashboardScene()
            .previewDisplayName("BridgeAI Dashboard")
    }
}
