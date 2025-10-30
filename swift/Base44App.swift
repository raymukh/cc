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
@MainActor
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
                    ReadinessStatusCard(readiness: model.readiness)

                    AssistiveHeroCard(
                        overview: model.overview
                    )

                    CalmModeSection(settings: $model.calmSettings)

                    AssistiveScenarioSection(scenarios: $model.scenarios)

                    SupplyCartSection(items: $model.supplyItems)
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
        VStack(alignment: .leading, spacing: 24) {
            Text(overview.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(overview.summary)
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .overlay(.white.opacity(0.18))

            HStack(spacing: 18) {
                MetricBadge(
                    icon: "magnifyingglass",
                    title: "AI Search",
                    detail: "Quickly pull any safety checklist you need."
                )

                MetricBadge(
                    icon: "waveform",
                    title: "Voice Assist",
                    detail: "Ask for next steps or confirm actions hands-free."
                )
            }

        }
        .padding(.vertical, 32)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(BridgeAITheme.primaryGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct ReadinessStatusCard: View {
    let readiness: EmergencyReadiness

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Automation status")
                        .font(.caption.bold())
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.85))

                    Text(readiness.statusLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.2))
                        )
                }

                Spacer()

                Text(readiness.formattedPercentage)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Divider()
                .overlay(Color.white.opacity(0.25))
                .padding(.vertical, 12)

            HStack(alignment: .center, spacing: 16) {
                ReadinessProgressCircle(progress: readiness.clampedProgress)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Readiness snapshot")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(readiness.detail)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BridgeAITheme.surface.opacity(0.4))
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BridgeAITheme.readinessGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12))
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct ReadinessProgressCircle: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(BridgeAITheme.primary.opacity(0.25), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [BridgeAITheme.primary, BridgeAITheme.primary.opacity(0.65)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(BridgeAITheme.primary.opacity(0.2))
                .frame(width: 18, height: 18)
                .offset(y: -28)
                .rotationEffect(.degrees(progress * 360))
                .opacity(progress > 0 ? 1 : 0)
        }
        .frame(width: 64, height: 64)
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
struct BridgeSymbol: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let deckHeight = height * 0.22
            let pillarWidth = width * 0.18
            let pillarHeight = height * 0.55
            let archHeight = height * 0.45

            ZStack {
                Path { path in
                    let leftStart = CGPoint(x: width * 0.12, y: height - deckHeight)
                    let rightStart = CGPoint(x: width * 0.88, y: height - deckHeight)
                    let control = CGPoint(x: width * 0.5, y: height - deckHeight - archHeight)

                    path.move(to: leftStart)
                    path.addQuadCurve(to: rightStart, control: control)
                    path.addLine(to: CGPoint(x: rightStart.x, y: rightStart.y + deckHeight * 0.4))
                    path.addQuadCurve(
                        to: CGPoint(x: leftStart.x, y: leftStart.y + deckHeight * 0.4),
                        control: CGPoint(x: width * 0.5, y: height - deckHeight - archHeight * 0.55)
                    )
                    path.closeSubpath()
                }
                .fill(.white.opacity(0.8))

                RoundedRectangle(cornerRadius: deckHeight / 2, style: .continuous)
                    .fill(.white)
                    .frame(width: width, height: deckHeight)
                    .position(x: width / 2, y: height - deckHeight / 2)

                HStack(spacing: width * 0.28) {
                    RoundedRectangle(cornerRadius: pillarWidth * 0.4, style: .continuous)
                        .fill(.white.opacity(0.85))
                        .frame(width: pillarWidth, height: pillarHeight)

                    RoundedRectangle(cornerRadius: pillarWidth * 0.4, style: .continuous)
                        .fill(.white.opacity(0.85))
                        .frame(width: pillarWidth, height: pillarHeight)
                }
                .position(x: width / 2, y: height - deckHeight - pillarHeight / 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
struct SupplyCartSection: View {
    @Binding var items: [SupplyItem]
    @State private var isPresentingAddItem = false

    var body: some View {
        BridgeAISection(title: "Supply Cart", subtitle: "Track inventory and reminders for essentials.") {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        SupplyItemRow(
                            item: item,
                            onToggle: { toggleItem(withID: item.id) },
                            onRemove: {
                                withAnimation(.easeInOut) {
                                    removeItem(withID: item.id)
                                }
                            }
                        )
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("supply-item-\(item.id.uuidString)")
                    }
                }

                Button {
                    isPresentingAddItem = true
                } label: {
                    Label("Add supply item", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BridgeAIActionButtonStyle(fullWidth: true))
            }
        }
        .sheet(isPresented: $isPresentingAddItem) {
            AddSupplyItemSheet { newItem in
                var updatedItems = items
                updatedItems.append(newItem)
                items = updatedItems
            }
        }
    }

    private func removeItem(withID id: SupplyItem.ID) {
        let updatedItems = items.filter { $0.id != id }
        items = updatedItems
    }

    private func toggleItem(withID id: SupplyItem.ID) {
        var updatedItems = items
        guard let index = updatedItems.firstIndex(where: { $0.id == id }) else { return }
        updatedItems[index].isOwned.toggle()
        items = updatedItems
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct SupplyItemRow: View {
    let item: SupplyItem
    var onToggle: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Image(systemName: item.isOwned ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(item.isOwned ? BridgeAITheme.primary : BridgeAITheme.textMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BridgeAITheme.textPrimary)
                if !item.detail.isEmpty {
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(BridgeAITheme.textSecondary)
                }
            }

            Spacer(minLength: 12)

            if let reminder = item.reminderDate {
                Text(reminder)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BridgeAITheme.accent)
            }

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(BridgeAITheme.merlot)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(BridgeAITheme.surfaceSecondary.opacity(0.7))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(item.name)")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BridgeAITheme.surface)
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct AddSupplyItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var detail: String = ""
    @State private var includeExpiryReminder: Bool = true
    @State private var reminderDate: Date = .now

    var onSave: (SupplyItem) -> Void

    private var reminderFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item details") {
                    TextField("Item name", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    TextField("Notes (optional)", text: $detail, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Expiry reminder") {
                    Toggle("Set expiry reminder", isOn: $includeExpiryReminder)

                    if includeExpiryReminder {
                        DatePicker(
                            "Expires on",
                            selection: $reminderDate,
                            displayedComponents: [.date]
                        )
                    }
                }
            }
            .navigationTitle("Add Supply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium])
#endif
    }

    private func save() {
        var reminderText: String?

        if includeExpiryReminder {
            reminderText = "Expires \(reminderFormatter.string(from: reminderDate))"
        }

        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = SupplyItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: trimmedDetail.isEmpty ? "" : trimmedDetail,
            isOwned: false,
            reminderDate: reminderText
        )

        onSave(item)
        dismiss()
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

                    EmergencyContactsSection(contacts: model.contacts)

                    EmergencyTriggerPanel(
                        mode: .voice,
                        model: model,
                        categories: model.categories
                    )

                    EmergencyTriggerPanel(
                        mode: .silent,
                        model: model,
                        categories: model.categories
                    )

                    if let activeEmergency = model.activeEmergency {
                        EmergencyActivationStatusView(
                            state: activeEmergency,
                            onCall911: { model.callEmergencyServices() },
                            onDeactivate: { model.deactivateEmergency() }
                        )
                    }

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
            Text("Automation status")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Trigger phrase", systemImage: "mic")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(model.triggerPhrase)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Divider().overlay(.white.opacity(0.2))

                HStack {
                    Label("Primary channel", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(model.primaryChannel)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Divider().overlay(.white.opacity(0.2))

                HStack(spacing: 18) {
                    MetricBadge(icon: "bolt.fill", title: "AI Response", detail: "Launches calls, GPS shares, and contact alerts instantly.")

                    MetricBadge(icon: "person.text.rectangle", title: "Multi-Sensory", detail: "Voice, visuals, and haptics stay active even when screens lock.")
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
struct EmergencyContactsSection: View {
    let contacts: [EmergencyContact]

    var body: some View {
        BridgeAISection(
            title: "Emergency contacts",
            subtitle: "Everyone who receives instant notifications when help is needed."
        ) {
            VStack(spacing: 14) {
                ForEach(contacts) { contact in
                    EmergencyContactRow(contact: contact)
                }

                Button("Manage contacts") {}
                    .buttonStyle(BridgeAITertiaryButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EmergencyContactRow: View {
    let contact: EmergencyContact

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BridgeAITheme.textPrimary)

                Text(contact.relationship)
                    .font(.caption)
                    .foregroundStyle(BridgeAITheme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Label(contact.phone, systemImage: "phone")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BridgeAITheme.primary)

                if contact.isPrimary {
                    Text("Primary contact")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(BridgeAITheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(BridgeAITheme.primary.opacity(0.08))
                        )
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

@available(iOS 16.0, macOS 13.0, *)
struct EmergencyTriggerPanel: View {
    let mode: EmergencyMode
    @ObservedObject var model: EmergencyModel
    let categories: [EmergencyCategory]

    @State private var contextNote: String = ""

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    }

    var body: some View {
        BridgeAISection(title: mode.displayTitle, subtitle: mode.subtitle) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(mode.prompt)
                        .font(.footnote)
                        .foregroundStyle(BridgeAITheme.textMuted)

                    TextField("Add extra details for responders", text: $contextNote, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(BridgeAITheme.surface)
                        )
                }

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(categories) { category in
                        Button {
                            model.activateEmergency(mode: mode, category: category, customMessage: contextNote)
                        } label: {
                            EmergencyCategoryButton(
                                category: category,
                                isSelected: model.activeEmergency?.mode == mode &&
                                    model.activeEmergency?.category.id == category.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Selecting an option immediately alerts your contacts and begins location tracking.")
                    .font(.caption)
                    .foregroundStyle(BridgeAITheme.textMuted)
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EmergencyCategoryButton: View {
    let category: EmergencyCategory
    var isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: category.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? .white : BridgeAITheme.primary)
                .padding(12)
                .background(
                    Circle()
                        .fill(isSelected ? BridgeAITheme.primary.opacity(0.4) : BridgeAITheme.primary.opacity(0.12))
                )

            Text(category.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : BridgeAITheme.textPrimary)

            Text(category.description)
                .font(.caption)
                .foregroundStyle(isSelected ? .white.opacity(0.9) : BridgeAITheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? BridgeAITheme.primary : BridgeAITheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    isSelected ? BridgeAITheme.primary.opacity(0.0) : BridgeAITheme.primary.opacity(0.12),
                    lineWidth: 1
                )
        )
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct EmergencyActivationStatusView: View {
    let state: ActiveEmergencyState
    var onCall911: () -> Void
    var onDeactivate: () -> Void

    private var timestampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        Circle().fill(.white.opacity(0.2))
                    )
                Text("Emergency active: \(state.mode.displayTitle) – \(state.category.title)")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 10) {
                Label("Notification sent to emergency contacts", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))

                Label("Location tracking is active", systemImage: "location.circle.fill")
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))

                if !state.note.isEmpty {
                    Label("Note shared: \(state.note)", systemImage: "text.bubble")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.footnote)
                }

                Text("Activated at \(timestampFormatter.string(from: state.activatedAt))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            HStack(spacing: 12) {
                Button("Call 911", action: onCall911)
                    .buttonStyle(BridgeAIActionButtonStyle(fullWidth: true))

                Button(action: onDeactivate) {
                    Text("I'm safe – Deactivate")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BridgeAITheme.merlot)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.white)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(0.35))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BridgeAITheme.merlotGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
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
struct BridgeAIIconLeadingLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 16) {
            configuration.icon
            configuration.title
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

struct EmergencyReadiness {
    var percentage: Double
    var statusLabel: String
    var detail: String

    var clampedProgress: Double {
        max(0, min(1, percentage / 100))
    }

    var formattedPercentage: String {
        let rounded = Int((percentage).rounded())
        return "\(rounded)%"
    }
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

struct SupplyItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var detail: String
    var isOwned: Bool
    var reminderDate: String?

    init(id: UUID = UUID(), name: String, detail: String, isOwned: Bool, reminderDate: String?) {
        self.id = id
        self.name = name
        self.detail = detail
        self.isOwned = isOwned
        self.reminderDate = reminderDate
    }
}

struct CalmSettings {
    var voiceGuidance: Bool
    var hapticSupport: Bool
    var highContrast: Bool
    var breathingPace: Int
}

@available(iOS 16.0, macOS 13.0, *)
final class AssistiveModel: ObservableObject {
    private let supplyStore = SupplyItemStore()

    @Published var overview: AssistiveOverview
    @Published var readiness: EmergencyReadiness
    @Published var scenarios: [CrisisScenario]
    @Published var supplyItems: [SupplyItem] {
        didSet {
            supplyStore.save(supplyItems)
        }
    }
    @Published var calmSettings: CalmSettings

    init(overview: AssistiveOverview, readiness: EmergencyReadiness, scenarios: [CrisisScenario], supplyItems: [SupplyItem], calmSettings: CalmSettings) {
        self.overview = overview
        self.readiness = readiness
        self.scenarios = scenarios
        self.calmSettings = calmSettings

        let persistedItems = supplyStore.load(defaultItems: supplyItems)
        self._supplyItems = Published(initialValue: persistedItems)
    }

    static func sample() -> AssistiveModel {
        AssistiveModel(
            overview: AssistiveOverview(
                title: "Be Prepared, Not Scared",
                summary: "Review these disaster plans to know exactly what to do when emergencies happen. Each plan includes before, during, and after guidance tailored to your safety."
            ),
            readiness: EmergencyReadiness(
                percentage: 62,
                statusLabel: "On Track",
                detail: "Contacts, supplies, and training check-ins are nearly complete."
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
                ),
                CrisisScenario(
                    title: "Tornado Warning",
                    summary: "Secure a safe room, shield heads, and communicate status updates.",
                    duration: "5 min",
                    actionLabel: "Open shelter checklist",
                    steps: [
                        "Move everyone to the lowest interior room away from windows.",
                        "Use helmets, cushions, or mattresses to protect heads and necks.",
                        "Shut doors, stay beneath sturdy furniture, and keep pets contained.",
                        "Send a quick status update to emergency contacts once secure."
                    ]
                )
            ],
            supplyItems: [
                SupplyItem(
                    name: "Dual-purpose first aid kit",
                    detail: "Include antihistamines, gloves, gauze, tourniquet.",
                    isOwned: true,
                    reminderDate: "Expires Aug 18"
                ),
                SupplyItem(
                    name: "Portable water filters",
                    detail: "Two-stage filters sized for four people.",
                    isOwned: false,
                    reminderDate: "Expires Jan 6"
                )
            ],
            calmSettings: CalmSettings(voiceGuidance: true, hapticSupport: true, highContrast: false, breathingPace: 6)
        )
    }
}

final class SupplyItemStore {
    private enum Constants {
        static let storageKey = "bridgeai.supplyItems"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(defaultItems: [SupplyItem]) -> [SupplyItem] {
        guard let data = defaults.data(forKey: Constants.storageKey) else {
            save(defaultItems)
            return defaultItems
        }

        do {
            return try JSONDecoder().decode([SupplyItem].self, from: data)
        } catch {
            save(defaultItems)
            return defaultItems
        }
    }

    func save(_ items: [SupplyItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: Constants.storageKey)
        } catch {
#if DEBUG
            print("Failed to persist supply items: \(error)")
#endif
        }
    }
}

struct EmergencyContact: Identifiable {
    let id = UUID()
    var name: String
    var relationship: String
    var phone: String
    var isPrimary: Bool
}

enum EmergencyMode: String {
    case voice
    case silent

    var displayTitle: String {
        switch self {
        case .voice: return "Voice Mode"
        case .silent: return "No Voice Mode"
        }
    }

    var subtitle: String {
        switch self {
        case .voice:
            return "Say a phrase or tap a scenario to launch full emergency automation."
        case .silent:
            return "Use discreet triggers when you cannot speak but still need help immediately."
        }
    }

    var prompt: String {
        switch self {
        case .voice:
            return "Add any context responders should hear once the call connects."
        case .silent:
            return "Type silent instructions or details to send with your alert."
        }
    }
}

struct EmergencyCategory: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var icon: String
    var description: String
}

struct ActiveEmergencyState: Identifiable {
    let id = UUID()
    var mode: EmergencyMode
    var category: EmergencyCategory
    var note: String
    var activatedAt: Date
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
@MainActor
final class EmergencyModel: ObservableObject {
    @Published var triggerPhrase: String
    @Published var primaryChannel: String
    @Published var contacts: [EmergencyContact]
    @Published var actions: [EmergencyAction]
    @Published var pathways: [EscalationPathway]
    @Published var evidenceSettings: EvidenceSettings
    @Published var activeEmergency: ActiveEmergencyState?

    let categories: [EmergencyCategory]

    init(
        triggerPhrase: String,
        primaryChannel: String,
        contacts: [EmergencyContact],
        actions: [EmergencyAction],
        pathways: [EscalationPathway],
        evidenceSettings: EvidenceSettings,
        categories: [EmergencyCategory],
        activeEmergency: ActiveEmergencyState? = nil
    ) {
        self.triggerPhrase = triggerPhrase
        self.primaryChannel = primaryChannel
        self.contacts = contacts
        self.actions = actions
        self.pathways = pathways
        self.evidenceSettings = evidenceSettings
        self.categories = categories
        self.activeEmergency = activeEmergency
    }

    func scheduleDrill() {
        // Placeholder for scheduling a drill notification or workflow
    }

    func activateEmergency(mode: EmergencyMode, category: EmergencyCategory, customMessage: String) {
        let trimmedNote = customMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        activeEmergency = ActiveEmergencyState(
            mode: mode,
            category: category,
            note: trimmedNote,
            activatedAt: .now
        )
    }

    func deactivateEmergency() {
        activeEmergency = nil
    }

    func callEmergencyServices() {
        // Placeholder for direct dial integration
    }

    static func sample() -> EmergencyModel {
        EmergencyModel(
            triggerPhrase: "Help me now",
            primaryChannel: "BridgeAI secure line",
            contacts: [
                EmergencyContact(name: "Taylor Morgan", relationship: "Partner", phone: "(415) 555-0198", isPrimary: true),
                EmergencyContact(name: "Jordan Lee", relationship: "Parent", phone: "(312) 555-0056", isPrimary: false),
                EmergencyContact(name: "Alex Kim", relationship: "Roommate", phone: "(206) 555-4421", isPrimary: false)
            ],
            actions: [
                EmergencyAction(
                    title: "Call 911 dispatcher",
                    detail: "Routes through the BridgeAI command desk with your location.",
                    icon: "phone.and.waveform",
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
            ),
            categories: [
                EmergencyCategory(title: "Medical", icon: "cross.case.fill", description: "Crises like seizures, allergic reactions, or sudden collapse."),
                EmergencyCategory(title: "Fire", icon: "flame.fill", description: "Active fires, smoke inhalation, or trapped occupants."),
                EmergencyCategory(title: "Crime/Violence", icon: "shield.fill", description: "Robbery, assault, kidnapping, or domestic violence."),
                EmergencyCategory(title: "Accident", icon: "car.fill", description: "Vehicle collisions, falls, or workplace incidents."),
                EmergencyCategory(title: "Natural Disaster", icon: "tornado", description: "Earthquakes, tornadoes, floods, or extreme weather."),
                EmergencyCategory(title: "Other Emergency", icon: "exclamationmark.triangle.fill", description: "Anything urgent that doesn’t fit a preset category.")
            ]
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
    static let background = Color(red: 0.953, green: 0.965, blue: 0.984) // #F3F6FB

    static let accent = Color(red: 0.902, green: 0.561, blue: 0.231) // custom warm accent
    static let textPrimary = Color(red: 0.141, green: 0.149, blue: 0.176)
    static let textSecondary = Color(red: 0.296, green: 0.318, blue: 0.357)
    static let textMuted = Color(red: 0.467, green: 0.47, blue: 0.472)
    static let surface = Color.white.opacity(0.82)
    static let surfacePrimary = Color(red: 0.977, green: 0.982, blue: 0.992)
    static let surfaceSecondary = Color(red: 0.94, green: 0.949, blue: 0.964)

    static let primaryGradient = LinearGradient(
        colors: [primary, primary.opacity(0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let readinessGradient = LinearGradient(
        colors: [
            primary.opacity(0.9),
            Color(red: 0.741, green: 0.859, blue: 0.91)
        ],
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
