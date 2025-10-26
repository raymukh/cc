import SwiftUI

// MARK: - Entry Point
@available(iOS 16.0, macOS 13.0, *)
@main
struct BridgeAIClientApp: App {
    var body: some Scene {
        WindowGroup {
            BridgeAIRootView()
        }
    }
}

// MARK: - Root Navigation
@available(iOS 16.0, macOS 13.0, *)
struct BridgeAIRootView: View {
    @StateObject private var model = BridgeAIAppModel()

    var body: some View {
        TabView(selection: $model.selectedTab) {
            AssistiveSupportView(model: model.assistiveModel)
                .tabItem { Label("Assistive", systemImage: "heart.text.square") }
                .tag(BridgeAIAppModel.Tab.assistive)

            EmergencyAutomationView(model: model.emergencyModel)
                .tabItem { Label("Emergency", systemImage: "bolt.trianglebadge.exclamationmark") }
                .tag(BridgeAIAppModel.Tab.emergency)

            LocationSafetyView(model: model.locationModel)
                .tabItem { Label("Location", systemImage: "location.circle") }
                .tag(BridgeAIAppModel.Tab.location)

            CourseLibraryView(model: model.courseModel)
                .tabItem { Label("Courses", systemImage: "book.closed") }
                .tag(BridgeAIAppModel.Tab.courses)
        }
        .accentColor(BridgeAITheme.primary)
    }
}

// MARK: - App Model
@available(iOS 16.0, macOS 13.0, *)
final class BridgeAIAppModel: ObservableObject {
    enum Tab: Hashable {
        case assistive
        case emergency
        case location
        case courses
    }

    @Published var selectedTab: Tab = .assistive
    @Published var assistiveModel = AssistiveModel.sample()
    @Published var emergencyModel = EmergencyModel.sample()
    @Published var locationModel = LocationModel.sample()
    @Published var courseModel = CourseModel.sample()
}

// MARK: - Assistive Page
@available(iOS 16.0, macOS 13.0, *)
struct AssistiveSupportView: View {
    @ObservedObject var model: AssistiveModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    AssistiveHeroCard(overview: model.overview)

                    AssistiveScenarioSection(scenarios: $model.scenarios)

                    DisasterPlanSection(plans: model.disasterPlans)

                    SupplyCartSection(items: $model.supplyItems)

                    CalmModeSection(settings: $model.calmSettings)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .background(BridgeAITheme.background.ignoresSafeArea())
            .navigationTitle("Assistive")
            .toolbarBackground(BridgeAITheme.background, for: .navigationBar)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct AssistiveHeroCard: View {
    let overview: AssistiveOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(overview.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(overview.summary)
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .overlay(.white.opacity(0.2))

            HStack(spacing: 18) {
                MetricBadge(icon: "clock.badge.checkmark", title: "Response Coach", detail: "Step-by-step prompts for urgent care situations.")

                MetricBadge(icon: "person.text.rectangle", title: "Multi-Sensory", detail: "Readable, audible, and haptic cues reduce panic.")
            }
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(BridgeAITheme.primaryGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.1))
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct MetricBadge: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(.white.opacity(0.12))
                )

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.06))
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct AssistiveScenarioSection: View {
    @Binding var scenarios: [CrisisScenario]

    var body: some View {
        BridgeAISection(title: "Guided Scenarios", subtitle: "Practical walkthroughs for unfolding situations.") {
            ForEach($scenarios) { $scenario in
                DisclosureGroup(isExpanded: $scenario.isExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(scenario.steps.indices), id: \.self) { index in
                            ScenarioStepRow(
                                stepNumber: index + 1,
                                text: scenario.steps[index]
                            )
                        }

                        Button(action: {}) {
                            Label(scenario.actionLabel, systemImage: "phone")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(BridgeAIActionButtonStyle())
                    }
                    .padding(.top, 12)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(scenario.title)
                                .font(.headline)
                                .foregroundStyle(BridgeAITheme.textPrimary)
                            Spacer()
                            Text(scenario.duration)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BridgeAITheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(BridgeAITheme.accent.opacity(0.12))
                                )
                        }

                        Text(scenario.summary)
                            .font(.subheadline)
                            .foregroundStyle(BridgeAITheme.textSecondary)
                    }
                }
                .disclosureGroupStyle(BridgeAICardDisclosureStyle())
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ScenarioStepRow: View {
    let stepNumber: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(BridgeAITheme.primary.opacity(0.12))
                .frame(width: 28, height: 28)
                .overlay(
                    Text("\(stepNumber)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BridgeAITheme.primary)
                )

            Text(text)
                .font(.callout)
                .foregroundStyle(BridgeAITheme.textPrimary)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct DisasterPlanSection: View {
    let plans: [DisasterPlan]
    @State private var currentIndex: Int = 0

    var body: some View {
        BridgeAISection(title: "Disaster Readiness", subtitle: "Before, during, and after playbooks with live inputs.") {
            GeometryReader { proxy in
                let arrowSpace: CGFloat = 52
                let spacing: CGFloat = 16
                let availableWidth = proxy.size.width
                let cardWidth = max(availableWidth - (arrowSpace * 2) - (spacing * 2), 280)

                HStack(spacing: spacing) {
                    slideshowArrow(direction: .previous) {
                        shiftPlan(by: -1)
                    }
                    .frame(width: arrowSpace)

                    ZStack {
                        if let plan = currentPlan {
                            DisasterPlanCard(plan: plan)
                                .frame(width: cardWidth)
                                .animation(.easeInOut(duration: 0.3), value: currentIndex)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title2)
                                    .foregroundStyle(BridgeAITheme.primary)

                                Text("No Plans Available")
                                    .font(.headline)
                                    .foregroundStyle(BridgeAITheme.textPrimary)

                                Text("Add readiness guides to see them here.")
                                    .font(.subheadline)
                                    .foregroundStyle(BridgeAITheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: cardWidth)
                            .padding(32)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(BridgeAITheme.surfacePrimary)
                            )
                        }
                    }
                    .frame(width: cardWidth, height: proxy.size.height)

                    slideshowArrow(direction: .next) {
                        shiftPlan(by: 1)
                    }
                    .frame(width: arrowSpace)
                }
                .frame(width: availableWidth, height: proxy.size.height)
            }
            .frame(height: 260)
        }
    }

    private var currentPlan: DisasterPlan? {
        guard !plans.isEmpty else { return nil }
        let safeIndex = min(currentIndex, plans.count - 1)
        return plans[safeIndex]
    }

    private func shiftPlan(by offset: Int) {
        guard !plans.isEmpty else { return }
        let nextIndex = currentIndex + offset
        currentIndex = min(max(nextIndex, 0), plans.count - 1)
    }

    private func slideshowArrow(direction: SlideDirection, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: direction == .previous ? "chevron.left" : "chevron.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(BridgeAITheme.textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(BridgeAITheme.surfaceSecondary.opacity(0.85))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction.accessibilityLabel)
    }
}

private enum SlideDirection {
    case previous
    case next

    var accessibilityLabel: String {
        switch self {
        case .previous:
            return "Previous plan"
        case .next:
            return "Next plan"
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct DisasterPlanCard: View {
    let plan: DisasterPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.name)
                    .font(.headline)
                    .foregroundStyle(BridgeAITheme.textPrimary)

                Spacer()

                Label(plan.alertLevel, systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(plan.alertColor)
                    .labelStyle(.trailingIcon)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(plan.checklist.prefix(3), id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(BridgeAITheme.primary)

                        Text(item)
                            .font(.callout)
                            .foregroundStyle(BridgeAITheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "cloud.sun")
                Text("Live feed: \(plan.dataSource)")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(BridgeAITheme.textMuted)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BridgeAITheme.surface)
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SupplyCartSection: View {
    @Binding var items: [SupplyItem]

    var body: some View {
        BridgeAISection(title: "Supply Cart", subtitle: "Track inventory and reminders for essentials.") {
            VStack(spacing: 12) {
                ForEach($items) { $item in
                    HStack(spacing: 14) {
                        Button {
                            item.isOwned.toggle()
                        } label: {
                            Image(systemName: item.isOwned ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(item.isOwned ? BridgeAITheme.primary : BridgeAITheme.textMuted)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BridgeAITheme.textPrimary)
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(BridgeAITheme.textSecondary)
                        }

                        Spacer()

                        if let reminder = item.reminderDate {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(reminder)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(BridgeAITheme.accent)
                                Text("Expiry check")
                                    .font(.caption2)
                                    .foregroundStyle(BridgeAITheme.textMuted)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BridgeAITheme.surface)
                    )
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct CalmModeSection: View {
    @Binding var settings: CalmSettings

    var body: some View {
        BridgeAISection(title: "Calm Mode", subtitle: "Accessibility-first cues to lower stress.") {
            VStack(alignment: .leading, spacing: 18) {
                Toggle(isOn: $settings.voiceGuidance) {
                    Label("Soothing narration", systemImage: "ear.badge.waveform")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Toggle(isOn: $settings.hapticSupport) {
                    Label("Rhythmic haptics", systemImage: "waveform.path")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Toggle(isOn: $settings.highContrast) {
                    Label("High-contrast cards", systemImage: "circle.lefthalf.filled")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Stepper(value: $settings.breathingPace, in: 4...12) {
                    HStack {
                        Text("Guided breathing pace")
                        Spacer()
                        Text("\(settings.breathingPace) cpm")
                            .foregroundStyle(BridgeAITheme.accent)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(BridgeAITheme.textPrimary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(BridgeAITheme.surface)
            )
        }
    }
}

// MARK: - Emergency Page
@available(iOS 16.0, macOS 13.0, *)
struct EmergencyAutomationView: View {
    @ObservedObject var model: EmergencyModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    EmergencyStatusCard(model: model)

                    EmergencyActionSection(actions: $model.actions)

                    EscalationPathSection(pathways: $model.pathways)

                    EvidenceCaptureSection(settings: $model.evidenceSettings)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .background(BridgeAITheme.background.ignoresSafeArea())
            .navigationTitle("Emergency")
            .toolbarBackground(BridgeAITheme.background, for: .navigationBar)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EmergencyStatusCard: View {
    @ObservedObject var model: EmergencyModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Automation readiness")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Trigger phrase", systemImage: "mic")
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Text(model.triggerPhrase)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Divider().overlay(.white.opacity(0.2))

                HStack {
                    Label("Primary channel", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Text(model.primaryChannel)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            Button("Run live drill") {
                model.scheduleDrill()
            }
            .buttonStyle(BridgeAIActionButtonStyle(fullWidth: true))
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(BridgeAITheme.emergencyGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.1))
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EmergencyActionSection: View {
    @Binding var actions: [EmergencyAction]

    var body: some View {
        BridgeAISection(title: "Immediate Actions", subtitle: "What fires automatically the second a trigger is heard.") {
            VStack(spacing: 16) {
                ForEach($actions) { $action in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center) {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .foregroundStyle(BridgeAITheme.primary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(BridgeAITheme.primary.opacity(0.12))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(action.title)
                                    .font(.headline)
                                Text(action.detail)
                                    .font(.footnote)
                                    .foregroundStyle(BridgeAITheme.textSecondary)
                            }

                            Spacer()

                            Toggle("", isOn: $action.isEnabled)
                                .labelsHidden()
                                .toggleStyle(BridgeAISwitchStyle())
                        }

                        if action.requiresContactSelection {
                            Picker("Escalate to", selection: $action.contact) {
                                ForEach(action.availableContacts, id: \.self) { contact in
                                    Text(contact).tag(contact)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.footnote)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(BridgeAITheme.surface)
                    )
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EscalationPathSection: View {
    @Binding var pathways: [EscalationPathway]

    var body: some View {
        BridgeAISection(title: "Escalation Path", subtitle: "How BridgeAI adjusts when you stop responding.") {
            VStack(spacing: 16) {
                ForEach($pathways) { $path in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(path.stage)
                                .font(.headline)
                            Spacer()
                            Text(path.delay)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BridgeAITheme.accent)
                        }

                        Text(path.summary)
                            .font(.footnote)
                            .foregroundStyle(BridgeAITheme.textSecondary)

                        if !path.actions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(path.actions, id: \.self) { action in
                                    HStack(spacing: 10) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(BridgeAITheme.primary)
                                            .font(.caption)
                                        Text(action)
                                            .font(.caption)
                                            .foregroundStyle(BridgeAITheme.textMuted)
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BridgeAITheme.surface)
                    )
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EvidenceCaptureSection: View {
    @Binding var settings: EvidenceSettings

    var body: some View {
        BridgeAISection(title: "Evidence Capture", subtitle: "Gather context silently and securely.") {
            VStack(alignment: .leading, spacing: 18) {
                Toggle(isOn: $settings.audioEnabled) {
                    Label("30-second audio snapshot", systemImage: "waveform.and.magnifyingglass")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Toggle(isOn: $settings.videoEnabled) {
                    Label("Front camera clip", systemImage: "video")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Toggle(isOn: $settings.smsFallback) {
                    Label("SMS fallback when offline", systemImage: "message.badge.waveform")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Picker("Retention", selection: $settings.retention) {
                    ForEach(EvidenceSettings.Retention.allCases, id: \.self) { retention in
                        Text(retention.label).tag(retention)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(BridgeAITheme.surface)
            )
        }
    }
}

// MARK: - Location Page
@available(iOS 16.0, macOS 13.0, *)
struct LocationSafetyView: View {
    @ObservedObject var model: LocationModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    LocationHeroCard(status: model.status)

                    SafeZoneSection(zones: $model.safeZones)

                    LocationAutomationSection(automation: $model.automation)

                    NearbySupportSection(services: model.nearbyServices)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .background(BridgeAITheme.background.ignoresSafeArea())
            .navigationTitle("Location")
            .toolbarBackground(BridgeAITheme.background, for: .navigationBar)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct LocationHeroCard: View {
    let status: LocationStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Secure sharing")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.white)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.currentLabel)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(status.updated)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                Divider().overlay(.white.opacity(0.2))

                HStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.white)
                    Text("Data encrypted, auto-expiring \(status.autoExpireMinutes) min after incident resolution.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            Button("Share live trail") {}
                .buttonStyle(BridgeAIActionButtonStyle(fullWidth: true))
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(BridgeAITheme.primaryGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.1))
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SafeZoneSection: View {
    @Binding var zones: [SafeZone]

    var body: some View {
        BridgeAISection(title: "Safe Zones", subtitle: "Watch doors, routes, and daily check-ins.") {
            VStack(spacing: 14) {
                ForEach($zones) { $zone in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(zone.name)
                                .font(.headline)
                            Spacer()
                            Toggle("", isOn: $zone.isMonitoring)
                                .labelsHidden()
                                .toggleStyle(BridgeAISwitchStyle())
                        }

                        Text(zone.window)
                            .font(.footnote)
                            .foregroundStyle(BridgeAITheme.textSecondary)

                        if let note = zone.note {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(BridgeAITheme.textMuted)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(BridgeAITheme.surface)
                    )
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct LocationAutomationSection: View {
    @Binding var automation: LocationAutomation

    var body: some View {
        BridgeAISection(title: "Escalation Logic", subtitle: "Escalate when movement stops or deviates.") {
            VStack(alignment: .leading, spacing: 18) {
                Toggle(isOn: $automation.motionCheck) {
                    Label("Detect prolonged stillness", systemImage: "figure.stand")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Toggle(isOn: $automation.routeDeviation) {
                    Label("Alert when off-route", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Toggle(isOn: $automation.lowBatteryFailsafe) {
                    Label("Escalate under 10% battery", systemImage: "battery.25")
                }
                .toggleStyle(BridgeAISwitchStyle())

                Stepper(value: $automation.checkInterval, in: 1...10) {
                    HStack {
                        Text("Check interval")
                        Spacer()
                        Text("Every \(automation.checkInterval) min")
                            .foregroundStyle(BridgeAITheme.accent)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(BridgeAITheme.textPrimary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(BridgeAITheme.surface)
            )
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct NearbySupportSection: View {
    let services: [NearbyService]

    var body: some View {
        BridgeAISection(title: "Nearby Support", subtitle: "Hospitals, stations, and shelters filtered to your scenario.") {
            VStack(spacing: 14) {
                ForEach(services) { service in
                    HStack(alignment: .center, spacing: 12) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BridgeAITheme.primary.opacity(0.12))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: service.icon)
                                    .font(.title3)
                                    .foregroundStyle(BridgeAITheme.primary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.name)
                                .font(.subheadline.weight(.semibold))
                            Text("\(service.distance) • updated \(service.updated)")
                                .font(.caption)
                                .foregroundStyle(BridgeAITheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(BridgeAITheme.textMuted)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BridgeAITheme.surface)
                    )
                }
            }
        }
    }
}

// MARK: - Courses Page
@available(iOS 16.0, macOS 13.0, *)
struct CourseLibraryView: View {
    @ObservedObject var model: CourseModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    CourseHeroCard(stats: model.stats)

                    FeaturedCourseSection(featured: model.featured)

                    CourseListSection(courses: $model.courses)

                    CertificationSection(partners: model.partners)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
            .background(BridgeAITheme.background.ignoresSafeArea())
            .navigationTitle("Courses")
            .toolbarBackground(BridgeAITheme.background, for: .navigationBar)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct CourseHeroCard: View {
    let stats: CourseStats

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Build readiness through practice")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(stats.completed) modules")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(stats.streak) day streak")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Keep it going")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Continue practice") {}
                .buttonStyle(BridgeAIActionButtonStyle(fullWidth: true))
        }
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(BridgeAITheme.merlotGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.1))
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct FeaturedCourseSection: View {
    let featured: CourseModule

    var body: some View {
        BridgeAISection(title: "Spotlight Simulation", subtitle: "Hands-on drills that adapt to your responses.") {
            VStack(alignment: .leading, spacing: 12) {
                Text(featured.title)
                    .font(.title3.weight(.semibold))

                Text(featured.description)
                    .font(.footnote)
                    .foregroundStyle(BridgeAITheme.textSecondary)

                HStack {
                    Label("Duration", systemImage: "timer")
                    Spacer()
                    Text(featured.duration)
                        .foregroundStyle(BridgeAITheme.accent)
                }
                .font(.caption.weight(.semibold))

                ProgressView(value: featured.progress)
                    .tint(BridgeAITheme.primary)
                    .shadow(color: BridgeAITheme.primary.opacity(0.2), radius: 8, x: 0, y: 4)

                Button("Resume module") {}
                    .buttonStyle(BridgeAIActionButtonStyle(fullWidth: true))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(BridgeAITheme.surface)
            )
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct CourseListSection: View {
    @Binding var courses: [CourseModule]

    var body: some View {
        BridgeAISection(title: "Micro Lessons", subtitle: "Bite-sized practice with knowledge checks.") {
            VStack(spacing: 14) {
                ForEach($courses) { $course in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(course.title)
                                    .font(.headline)
                                Text(course.focusArea)
                                    .font(.caption)
                                    .foregroundStyle(BridgeAITheme.textMuted)
                            }
                            Spacer()
                            Text(course.badge.uppercased())
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(BridgeAITheme.primary)
                                )
                        }

                        ProgressView(value: course.progress)
                            .tint(BridgeAITheme.primary)

                        HStack {
                            Label("Quiz", systemImage: "checkmark.shield")
                            Spacer()
                            Text("\(course.duration) • \(course.level)")
                        }
                        .font(.caption)
                        .foregroundStyle(BridgeAITheme.textSecondary)

                        Button(course.isDownloaded ? "Remove download" : "Download for offline") {
                            course.isDownloaded.toggle()
                        }
                        .buttonStyle(BridgeAITertiaryButtonStyle())
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(BridgeAITheme.surface)
                    )
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct CertificationSection: View {
    let partners: [CertificationPartner]

    var body: some View {
        BridgeAISection(title: "Certifications", subtitle: "Advance with recognized partners.") {
            VStack(spacing: 16) {
                ForEach(partners) { partner in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(partner.name)
                                .font(.subheadline.weight(.semibold))
                            Text(partner.focus)
                                .font(.caption)
                                .foregroundStyle(BridgeAITheme.textSecondary)
                        }
                        Spacer()
                        Button("View pathway") {}
                            .buttonStyle(BridgeAITertiaryButtonStyle())
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BridgeAITheme.surface)
                    )
                }
            }
        }
    }
}

// MARK: - Shared Components
@available(iOS 16.0, macOS 13.0, *)
struct BridgeAISection<Content: View>: View {
    let title: String
    let subtitle: String
    private let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BridgeAITheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(BridgeAITheme.textMuted)
            }

            content
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct BridgeAIActionButtonStyle: ButtonStyle {
    var fullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? BridgeAITheme.primary.opacity(0.8) : BridgeAITheme.primary)
            )
            .shadow(color: BridgeAITheme.primary.opacity(configuration.isPressed ? 0 : 0.25), radius: 12, x: 0, y: 8)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct BridgeAITertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundStyle(BridgeAITheme.primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(BridgeAITheme.primary.opacity(configuration.isPressed ? 0.16 : 0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(BridgeAITheme.primary.opacity(0.2), lineWidth: 1)
            )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct BridgeAISwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundStyle(BridgeAITheme.textPrimary)
            Spacer()
            Toggle(isOn: configuration.$isOn) {
                EmptyView()
            }
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(BridgeAITheme.primary)
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct BridgeAICardDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { configuration.isExpanded.toggle() }) {
                HStack {
                    configuration.label
                    Spacer()
                    Image(systemName: configuration.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BridgeAITheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if configuration.isExpanded {
                configuration.content
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(BridgeAITheme.surface)
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            Spacer(minLength: 8)
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

// MARK: - Data Models
struct AssistiveOverview {
    let title: String
    let summary: String
}

struct CrisisScenario: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let duration: String
    let actionLabel: String
    var steps: [String]
    var isExpanded: Bool = false
}

struct DisasterPlan: Identifiable {
    let id = UUID()
    let name: String
    let alertLevel: String
    let alertColor: Color
    let dataSource: String
    let checklist: [String]
}

struct SupplyItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    var isOwned: Bool
    var reminderDate: String?
}

struct CalmSettings {
    var voiceGuidance: Bool
    var hapticSupport: Bool
    var highContrast: Bool
    var breathingPace: Int
}

@available(iOS 16.0, macOS 13.0, *)
final class AssistiveModel: ObservableObject {
    @Published var overview: AssistiveOverview
    @Published var scenarios: [CrisisScenario]
    @Published var disasterPlans: [DisasterPlan]
    @Published var supplyItems: [SupplyItem]
    @Published var calmSettings: CalmSettings

    init(overview: AssistiveOverview, scenarios: [CrisisScenario], disasterPlans: [DisasterPlan], supplyItems: [SupplyItem], calmSettings: CalmSettings) {
        self.overview = overview
        self.scenarios = scenarios
        self.disasterPlans = disasterPlans
        self.supplyItems = supplyItems
        self.calmSettings = calmSettings
    }

    static func sample() -> AssistiveModel {
        AssistiveModel(
            overview: AssistiveOverview(
                title: "Guidance when seconds count",
                summary: "Follow adaptive prompts to keep someone safe before first responders arrive."
            ),
            scenarios: [
                CrisisScenario(
                    title: "Support during a seizure",
                    summary: "Keep breathing clear, time the episode, and check for recovery signs.",
                    duration: "4 min",
                    actionLabel: "Call emergency services",
                    steps: [
                        "Ease the person to the ground and roll onto their side.",
                        "Protect the head with something soft; loosen tight clothing.",
                        "Track the length of the seizure inside the app timer.",
                        "If activity passes five minutes or repeats, escalate immediately."
                    ]
                ),
                CrisisScenario(
                    title: "Severe allergic reaction",
                    summary: "Spot breathing trouble, deploy epinephrine, and prepare for EMS.",
                    duration: "3 min",
                    actionLabel: "Alert nearest hospital",
                    steps: [
                        "Check airway and remove any visible trigger if safe.",
                        "Administer auto-injector and note the time.",
                        "Start Calm Mode instructions to steady breathing.",
                        "Prepare for a second dose if symptoms persist in five minutes."
                    ]
                ),
                CrisisScenario(
                    title: "Flash flood response",
                    summary: "Move to higher ground and secure essential gear for evacuation.",
                    duration: "6 min",
                    actionLabel: "Message family safety list",
                    steps: [
                        "Collect medical kits, water, and identification documents.",
                        "Power down utilities if advised by authorities.",
                        "Move to a higher floor or roof with bright markers.",
                        "Switch communications to text for reliable status updates."
                    ]
                )
            ],
            disasterPlans: [
                DisasterPlan(
                    name: "Tornado shelter prep",
                    alertLevel: "Warning", alertColor: BridgeAITheme.accent,
                    dataSource: "NOAA feed",
                    checklist: [
                        "Move to an interior room away from windows.",
                        "Use helmets or head protection for everyone.",
                        "Ping trusted contacts with a quick status."
                    ]
                ),
                DisasterPlan(
                    name: "Wildfire evacuation",
                    alertLevel: "Watch", alertColor: BridgeAITheme.primary,
                    dataSource: "FEMA alerts",
                    checklist: [
                        "Seal vents, close windows, and stage the go-bag.",
                        "Load evac route with live traffic from DOT.",
                        "Enable smoke trigger for air quality monitor."
                    ]
                ),
                DisasterPlan(
                    name: "Earthquake aftermath",
                    alertLevel: "Advisory", alertColor: BridgeAITheme.textSecondary,
                    dataSource: "USGS updates",
                    checklist: [
                        "Check gas, water, and electrical lines for damage.",
                        "Photograph structural changes for claims.",
                        "Locate nearby shelters and register arrival."
                    ]
                ),
                DisasterPlan(
                    name: "Extended outage",
                    alertLevel: "Monitor", alertColor: BridgeAITheme.textSecondary,
                    dataSource: "Local utility",
                    checklist: [
                        "Track fridge temperature every two hours.",
                        "Rotate battery packs and keep them charged.",
                        "Share location heartbeat every 30 minutes."
                    ]
                )
            ],
            supplyItems: [
                SupplyItem(name: "Dual-purpose first aid kit", detail: "Include antihistamines, gloves, gauze, tourniquet.", isOwned: true, reminderDate: "Check in 45 days"),
                SupplyItem(name: "Portable water filters", detail: "Two-stage filters sized for four people.", isOwned: false, reminderDate: nil),
                SupplyItem(name: "Spare power banks", detail: "Keep above 80% charge, rotate monthly.", isOwned: true, reminderDate: "Test on Apr 12"),
                SupplyItem(name: "Emergency blankets", detail: "Vacuum sealed, heat reflective.", isOwned: false, reminderDate: nil)
            ],
            calmSettings: CalmSettings(voiceGuidance: true, hapticSupport: true, highContrast: false, breathingPace: 6)
        )
    }
}

struct EmergencyAction: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    var isEnabled: Bool
    var requiresContactSelection: Bool
    var contact: String
    var availableContacts: [String]
}

struct EscalationPathway: Identifiable {
    let id = UUID()
    let stage: String
    let delay: String
    let summary: String
    var actions: [String]
}

struct EvidenceSettings {
    enum Retention: CaseIterable {
        case twelveHours
        case twentyFourHours
        case threeDays

        var label: String {
            switch self {
            case .twelveHours: return "12h"
            case .twentyFourHours: return "24h"
            case .threeDays: return "3d"
            }
        }
    }

    var audioEnabled: Bool
    var videoEnabled: Bool
    var smsFallback: Bool
    var retention: Retention
}

@available(iOS 16.0, macOS 13.0, *)
final class EmergencyModel: ObservableObject {
    @Published var triggerPhrase: String
    @Published var primaryChannel: String
    @Published var actions: [EmergencyAction]
    @Published var pathways: [EscalationPathway]
    @Published var evidenceSettings: EvidenceSettings

    init(triggerPhrase: String, primaryChannel: String, actions: [EmergencyAction], pathways: [EscalationPathway], evidenceSettings: EvidenceSettings) {
        self.triggerPhrase = triggerPhrase
        self.primaryChannel = primaryChannel
        self.actions = actions
        self.pathways = pathways
        self.evidenceSettings = evidenceSettings
    }

    func scheduleDrill() {
        // Placeholder for scheduling a drill notification or workflow
    }

    static func sample() -> EmergencyModel {
        EmergencyModel(
            triggerPhrase: "Help me now",
            primaryChannel: "911 bridge + 3 trusted contacts",
            actions: [
                EmergencyAction(
                    title: "Dial emergency services",
                    detail: "Places a call and transmits your live location.",
                    icon: "phone.fill.arrow.up.right",
                    isEnabled: true,
                    requiresContactSelection: false,
                    contact: "",
                    availableContacts: []
                ),
                EmergencyAction(
                    title: "Notify trusted circle",
                    detail: "Sends SMS with GPS trail and situation summary.",
                    icon: "person.3.sequence",
                    isEnabled: true,
                    requiresContactSelection: true,
                    contact: "Taylor – Partner",
                    availableContacts: ["Taylor – Partner", "Jordan – Parent", "Alex – Roommate"]
                ),
                EmergencyAction(
                    title: "Live coaching",
                    detail: "Keeps a two-way voice link open for instructions.",
                    icon: "wave.3.right",
                    isEnabled: true,
                    requiresContactSelection: false,
                    contact: "",
                    availableContacts: []
                ),
                EmergencyAction(
                    title: "Record encrypted clip",
                    detail: "Captures 20s audio/video evidence with secure storage.",
                    icon: "video.badge.waveform",
                    isEnabled: false,
                    requiresContactSelection: false,
                    contact: "",
                    availableContacts: []
                )
            ],
            pathways: [
                EscalationPathway(
                    stage: "Stage 1",
                    delay: "30 sec",
                    summary: "Verifies response by requesting voice or tap input.",
                    actions: ["Send silent prompt", "Ping wearable for tap confirmation"]
                ),
                EscalationPathway(
                    stage: "Stage 2",
                    delay: "90 sec",
                    summary: "No response triggers silent background mode.",
                    actions: ["Enable discreet recording", "Share coordinates with dispatch"]
                ),
                EscalationPathway(
                    stage: "Stage 3",
                    delay: "3 min",
                    summary: "Notify secondary contact list and mark device as compromised.",
                    actions: ["Send safe word override instructions", "Pulse status every 60s"]
                )
            ],
            evidenceSettings: EvidenceSettings(
                audioEnabled: true,
                videoEnabled: false,
                smsFallback: true,
                retention: .twentyFourHours
            )
        )
    }
}

struct LocationStatus {
    let currentLabel: String
    let updated: String
    let autoExpireMinutes: Int
}

struct SafeZone: Identifiable {
    let id = UUID()
    let name: String
    let window: String
    var isMonitoring: Bool
    var note: String?
}

struct LocationAutomation {
    var motionCheck: Bool
    var routeDeviation: Bool
    var lowBatteryFailsafe: Bool
    var checkInterval: Int
}

struct NearbyService: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let distance: String
    let updated: String
}

@available(iOS 16.0, macOS 13.0, *)
final class LocationModel: ObservableObject {
    @Published var status: LocationStatus
    @Published var safeZones: [SafeZone]
    @Published var automation: LocationAutomation
    @Published var nearbyServices: [NearbyService]

    init(status: LocationStatus, safeZones: [SafeZone], automation: LocationAutomation, nearbyServices: [NearbyService]) {
        self.status = status
        self.safeZones = safeZones
        self.automation = automation
        self.nearbyServices = nearbyServices
    }

    static func sample() -> LocationModel {
        LocationModel(
            status: LocationStatus(
                currentLabel: "Downtown response hub",
                updated: "Updated 2 min ago",
                autoExpireMinutes: 45
            ),
            safeZones: [
                SafeZone(name: "Home base", window: "Arrive by 7:30 PM on weekdays", isMonitoring: true, note: "Auto-share with Taylor and Jordan."),
                SafeZone(name: "Campus lab", window: "Check-in every 3 hours", isMonitoring: false, note: "Notify advisor if missed twice."),
                SafeZone(name: "Gym route", window: "Alert if off-route >0.5 mi", isMonitoring: true, note: nil)
            ],
            automation: LocationAutomation(motionCheck: true, routeDeviation: true, lowBatteryFailsafe: true, checkInterval: 3),
            nearbyServices: [
                NearbyService(name: "City Medical Center ER", icon: "cross.case", distance: "1.1 mi", updated: "5 min ago"),
                NearbyService(name: "Central Police Precinct", icon: "shield.lefthalf.fill", distance: "0.9 mi", updated: "7 min ago"),
                NearbyService(name: "Community Shelter 12", icon: "house", distance: "2.3 mi", updated: "11 min ago")
            ]
        )
    }
}

struct CourseStats {
    let completed: Int
    let streak: Int
}

struct CourseModule: Identifiable {
    let id = UUID()
    let title: String
    let focusArea: String
    let duration: String
    let level: String
    let badge: String
    var progress: Double
    var isDownloaded: Bool
    let description: String
}

struct CertificationPartner: Identifiable {
    let id = UUID()
    let name: String
    let focus: String
}

@available(iOS 16.0, macOS 13.0, *)
final class CourseModel: ObservableObject {
    @Published var stats: CourseStats
    @Published var featured: CourseModule
    @Published var courses: [CourseModule]
    @Published var partners: [CertificationPartner]

    init(stats: CourseStats, featured: CourseModule, courses: [CourseModule], partners: [CertificationPartner]) {
        self.stats = stats
        self.featured = featured
        self.courses = courses
        self.partners = partners
    }

    static func sample() -> CourseModel {
        let featured = CourseModule(
            title: "Mass casualty triage drill",
            focusArea: "Rapid patient assessment",
            duration: "15 min",
            level: "Intermediate",
            badge: "Simulation",
            progress: 0.55,
            isDownloaded: true,
            description: "Practice START triage with branching decisions that adapt to your choices."
        )

        let courses = [
            CourseModule(
                title: "Hands-only CPR essentials",
                focusArea: "First Aid",
                duration: "7 min",
                level: "Beginner",
                badge: "Core",
                progress: 0.8,
                isDownloaded: true,
                description: "Learn compression cadence, depth, and rotation strategy."
            ),
            CourseModule(
                title: "Stop the bleed fundamentals",
                focusArea: "Trauma response",
                duration: "9 min",
                level: "Intermediate",
                badge: "Skill",
                progress: 0.35,
                isDownloaded: false,
                description: "Tourniquet placement drills with timed challenges."
            ),
            CourseModule(
                title: "Family wildfire plan",
                focusArea: "Disaster readiness",
                duration: "5 min",
                level: "All levels",
                badge: "Plan",
                progress: 0.1,
                isDownloaded: false,
                description: "Design evacuation roles and communication routines."
            )
        ]

        let partners = [
            CertificationPartner(name: "Red Cross Ready", focus: "Community response"),
            CertificationPartner(name: "FEMA CERT", focus: "Incident command"),
            CertificationPartner(name: "SafeTech Labs", focus: "Digital crisis management")
        ]

        return CourseModel(
            stats: CourseStats(completed: 18, streak: 6),
            featured: featured,
            courses: courses,
            partners: partners
        )
    }
}

// MARK: - Theme
enum BridgeAITheme {
    static let primary = Color(red: 0.082, green: 0.376, blue: 0.478) // #15607A
    static let merlot = Color(red: 0.239, green: 0.031, blue: 0.078) // #3D0814
    static let background = Color(red: 0.992, green: 0.996, blue: 0.918) // #FFFEEA

    static let accent = Color(red: 0.902, green: 0.561, blue: 0.231) // custom warm accent
    static let textPrimary = Color(red: 0.141, green: 0.149, blue: 0.176)
    static let textSecondary = Color(red: 0.296, green: 0.318, blue: 0.357)
    static let textMuted = Color(red: 0.467, green: 0.47, blue: 0.472)
    static let surface = Color.white.opacity(0.82)
    static let surfacePrimary = Color(red: 1.0, green: 0.991, blue: 0.94)
    static let surfaceSecondary = Color(red: 0.953, green: 0.964, blue: 0.968)

    static let primaryGradient = LinearGradient(
        colors: [primary, primary.opacity(0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let emergencyGradient = LinearGradient(
        colors: [merlot, Color(red: 0.545, green: 0.109, blue: 0.157)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let merlotGradient = LinearGradient(
        colors: [merlot, Color(red: 0.39, green: 0.063, blue: 0.129)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
