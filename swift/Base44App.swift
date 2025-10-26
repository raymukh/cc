import SwiftUI

// MARK: - Entry point
@available(iOS 16.0, macOS 13.0, *)
@main
struct BridgeAIClientApp: App {
    var body: some Scene {
        WindowGroup {
            BridgeAIDashboardView()
        }
    }
}

// MARK: - Root scene
@available(iOS 16.0, macOS 13.0, *)
struct BridgeAIDashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = BridgeAIDashboardModel.sample()
    @State private var showSupportSheet = false

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var layout: BridgeAIDashboardLayout {
        isCompact ? .compact : .regular
    }

    var body: some View {
        Group {
            if isCompact {
                NavigationStack {
                    DashboardScrollView(model: model, layout: layout)
                        .navigationTitle(model.overview.appName)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showSupportSheet = true
                                } label: {
                                    Label("Support", systemImage: "lifepreserver")
                                }
                            }
                        }
                }
                .sheet(isPresented: $showSupportSheet) {
                    SupportDirectoryView(resources: model.supportResources)
                }
            } else {
                HStack(spacing: 0) {
                    SidebarPanel(
                        overview: model.overview,
                        contacts: model.trustedContacts,
                        resources: model.supportResources
                    )
                    .frame(width: 320)
                    .background(BridgeAIColors.midnight.gradient(inset: true))
                    .foregroundStyle(.white)
                    .ignoresSafeArea()

                    DashboardScrollView(model: model, layout: layout)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(BridgeAIColors.surfaceBackground)
                }
                .background(BridgeAIColors.surfaceBackground)
            }
        }
        .background(BridgeAIColors.surfaceBackground.ignoresSafeArea())
    }
}

// MARK: - Layout configuration
struct BridgeAIDashboardLayout {
    let isCompact: Bool
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let contentSpacing: CGFloat
    let highlightSpacing: CGFloat
    let highlightColumns: [GridItem]

    static let compact = BridgeAIDashboardLayout(
        isCompact: true,
        horizontalPadding: 20,
        verticalPadding: 24,
        contentSpacing: 26,
        highlightSpacing: 16,
        highlightColumns: [
            GridItem(.flexible(minimum: 140), spacing: 14, alignment: .top)
        ]
    )

    static let regular = BridgeAIDashboardLayout(
        isCompact: false,
        horizontalPadding: 36,
        verticalPadding: 40,
        contentSpacing: 32,
        highlightSpacing: 20,
        highlightColumns: [
            GridItem(.flexible(minimum: 180), spacing: 18, alignment: .top),
            GridItem(.flexible(minimum: 180), spacing: 18, alignment: .top)
        ]
    )
}

// MARK: - Sidebar
@available(iOS 16.0, macOS 13.0, *)
struct SidebarPanel: View {
    let overview: BridgeAIOverview
    let contacts: [TrustedContact]
    let resources: [SupportResource]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BridgeAIColors.copper.gradient(inset: true))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(overview.appName)
                            .font(.title2.weight(.semibold))
                        Text(overview.tagline)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Trusted Circle")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(contacts) { contact in
                            HStack(alignment: .center, spacing: 12) {
                                Circle()
                                    .fill(BridgeAIColors.deepSea.opacity(0.35))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: contact.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(contact.relationship)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.white.opacity(0.08))
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Emergency Directory")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(resources) { resource in
                            HStack(alignment: .center, spacing: 12) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white.opacity(0.14))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: resource.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resource.label)
                                        .font(.subheadline.weight(.semibold))
                                    Text(resource.detail)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Dashboard content
@available(iOS 16.0, macOS 13.0, *)
struct DashboardScrollView: View {
    @ObservedObject var model: BridgeAIDashboardModel
    let layout: BridgeAIDashboardLayout

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: layout.contentSpacing) {
                HeroBannerView(overview: model.overview, layout: layout)

                MissionHighlightsView(highlights: model.highlights, layout: layout)

                ForEach(model.capabilityGroups) { group in
                    CapabilityGroupSection(group: group, layout: layout)
                }

                CoursesShowcaseView(courses: model.courses, layout: layout)

                SupportResourcesFooter(resources: model.supportResources)
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.vertical, layout.verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(BridgeAIColors.surfaceBackground)
    }
}

// MARK: - Hero
@available(iOS 16.0, macOS 13.0, *)
struct HeroBannerView: View {
    let overview: BridgeAIOverview
    let layout: BridgeAIDashboardLayout

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: layout.isCompact ? 28 : 32, style: .continuous)
                .fill(BridgeAIColors.sunrise.gradient())
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(BridgeAIColors.sunriseHighlight)
                        .frame(width: layout.isCompact ? 140 : 190)
                        .offset(x: layout.isCompact ? 40 : 60, y: layout.isCompact ? -60 : -80)
                        .blur(radius: 24)
                        .opacity(0.6)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: layout.isCompact ? 28 : 32, style: .continuous)
                        .stroke(BridgeAIColors.sunriseAccent.opacity(0.25), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: layout.isCompact ? 16 : 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(overview.tagline.uppercased())
                        .font(.caption.weight(.semibold))
                        .tracking(1.6)
                        .foregroundStyle(BridgeAIColors.sunriseAccent.opacity(0.9))
                    Text(overview.mission)
                        .font(.system(size: layout.isCompact ? 28 : 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                }

                Text(overview.introduction)
                    .font(layout.isCompact ? .callout : .title3)
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .background(.white.opacity(0.25))

                HStack(alignment: .center, spacing: 16) {
                    Label {
                        Text("Preparedness in your pocket")
                            .font(.subheadline.weight(.medium))
                    } icon: {
                        Image(systemName: "sparkle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, BridgeAIColors.sunriseAccent)
                    }
                    .labelStyle(.iconLeading)

                    Spacer()

                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.2))
                        .frame(width: layout.isCompact ? 110 : 140, height: 34)
                        .overlay(
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Live ready")
                                    .font(.footnote.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                        )
                }
            }
            .padding(layout.isCompact ? 24 : 30)
        }
    }
}

// MARK: - Mission highlights
@available(iOS 16.0, macOS 13.0, *)
struct MissionHighlightsView: View {
    let highlights: [MissionHighlight]
    let layout: BridgeAIDashboardLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why BridgeAI Matters")
                .font(.title3.weight(.semibold))
                .foregroundStyle(BridgeAIColors.title)

            LazyVGrid(columns: layout.highlightColumns, spacing: layout.highlightSpacing) {
                ForEach(highlights) { highlight in
                    HighlightCard(highlight: highlight, isCompact: layout.isCompact)
                }
            }
        }
    }
}

// MARK: - Label styles
struct BridgeAIIconLeadingLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == BridgeAIIconLeadingLabelStyle {
    static var iconLeading: BridgeAIIconLeadingLabelStyle { .init() }
}

@available(iOS 16.0, macOS 13.0, *)
struct HighlightCard: View {
    let highlight: MissionHighlight
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(highlight.accent.gradient(inset: true))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: highlight.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                )

            Text(highlight.title)
                .font(.headline)
                .foregroundStyle(BridgeAIColors.title)

            Text(highlight.detail)
                .font(isCompact ? .footnote : .callout)
                .foregroundStyle(BridgeAIColors.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(isCompact ? 18 : 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BridgeAIColors.lavender)
                .shadow(color: BridgeAIColors.shadow.opacity(0.08), radius: 16, x: 0, y: 12)
        )
    }
}

// MARK: - Capability sections
@available(iOS 16.0, macOS 13.0, *)
struct CapabilityGroupSection: View {
    let group: CapabilityGroup
    let layout: BridgeAIDashboardLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(group.gradient.gradient())
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: group.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.title)
                            .font(.title3.weight(.semibold))
                        Text(group.caption)
                            .font(.callout)
                            .foregroundStyle(BridgeAIColors.body)
                    }
                }

                Text(group.context)
                    .font(.subheadline)
                    .foregroundStyle(BridgeAIColors.bodySecondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(group.features) { feature in
                    CapabilityFeatureRow(feature: feature, accent: group.gradient)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(BridgeAIColors.lavender)
                    .shadow(color: BridgeAIColors.shadow.opacity(0.08), radius: 16, x: 0, y: 10)
            )

            if let action = group.cta {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: action.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(group.gradient.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.label)
                            .font(.subheadline.weight(.semibold))
                        Text(action.detail)
                            .font(.footnote)
                            .foregroundStyle(BridgeAIColors.bodySecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(BridgeAIColors.bodySecondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(group.gradient.primary.opacity(0.12))
                )
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct CapabilityFeatureRow: View {
    let feature: CapabilityFeature
    let accent: BridgeAIGradientSwatch

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(accent.gradient(inset: true))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: feature.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.detail)
                    .font(.subheadline)
                    .foregroundStyle(BridgeAIColors.bodySecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Courses showcase
@available(iOS 16.0, macOS 13.0, *)
struct CoursesShowcaseView: View {
    let courses: [CourseModule]
    let layout: BridgeAIDashboardLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Courses to Build Confidence")
                .font(.title3.weight(.semibold))
                .foregroundStyle(BridgeAIColors.title)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(courses) { course in
                        CourseCard(course: course, isCompact: layout.isCompact)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct CourseCard: View {
    let course: CourseModule
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(course.accent.gradient(inset: true))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: course.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.badge)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(course.accent.primary)
                    Text(course.title)
                        .font(.headline)
                }
            }

            Text(course.description)
                .font(isCompact ? .footnote : .callout)
                .foregroundStyle(BridgeAIColors.bodySecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BridgeAIColors.bodySecondary)
                Text(course.duration)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BridgeAIColors.bodySecondary)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(course.accent.primary)
            }
        }
        .padding(isCompact ? 18 : 22)
        .frame(width: isCompact ? 240 : 280, height: isCompact ? 200 : 220)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BridgeAIColors.lavender)
                .shadow(color: BridgeAIColors.shadow.opacity(0.08), radius: 14, x: 0, y: 10)
        )
    }
}

// MARK: - Support footer
@available(iOS 16.0, macOS 13.0, *)
struct SupportResourcesFooter: View {
    let resources: [SupportResource]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Ready When It Matters")
                .font(.title3.weight(.semibold))
                .foregroundStyle(BridgeAIColors.title)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(resources.prefix(3)) { resource in
                    HStack(alignment: .center, spacing: 14) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(resource.tint.gradient(inset: true))
                            .frame(width: 46, height: 46)
                            .overlay(
                                Image(systemName: resource.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(resource.label)
                                .font(.headline)
                            Text(resource.detail)
                                .font(.subheadline)
                                .foregroundStyle(BridgeAIColors.bodySecondary)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BridgeAIColors.midnight.gradient())
        )
        .foregroundStyle(.white)
    }
}

// MARK: - Support directory sheet
@available(iOS 16.0, macOS 13.0, *)
struct SupportDirectoryView: View {
    let resources: [SupportResource]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Emergency Services") {
                    ForEach(resources) { resource in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resource.label)
                                .font(.headline)
                            Text(resource.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Support Directory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium, .large])
#endif
    }
}

// MARK: - View model & data
@available(iOS 16.0, macOS 13.0, *)
final class BridgeAIDashboardModel: ObservableObject {
    @Published var overview: BridgeAIOverview
    @Published var highlights: [MissionHighlight]
    @Published var capabilityGroups: [CapabilityGroup]
    @Published var courses: [CourseModule]
    @Published var supportResources: [SupportResource]
    @Published var trustedContacts: [TrustedContact]

    init(
        overview: BridgeAIOverview,
        highlights: [MissionHighlight],
        capabilityGroups: [CapabilityGroup],
        courses: [CourseModule],
        supportResources: [SupportResource],
        trustedContacts: [TrustedContact]
    ) {
        self.overview = overview
        self.highlights = highlights
        self.capabilityGroups = capabilityGroups
        self.courses = courses
        self.supportResources = supportResources
        self.trustedContacts = trustedContacts
    }

    static func sample() -> BridgeAIDashboardModel {
        BridgeAIDashboardModel(
            overview: .init(
                appName: "BridgeAI",
                tagline: "The bridge between you and first responders",
                mission: "Because every second matters.",
                introduction: "BridgeAI keeps you, your family, and your community in sync before, during, and after emergencies. From calm coaching to silent rescue protocols, the app adapts to how much time you have and how much help you need.",
                pledge: "We protect privacy, honor consent, and operate with verified data sources in every response."
            ),
            highlights: [
                .init(
                    title: "Nationwide Coverage",
                    detail: "Real-time FEMA and NOAA signals pair with hyperlocal insights so you know what's happening before anyone else.",
                    icon: "antenna.radiowaves.left.and.right",
                    accent: .init(primary: BridgeAIColors.deepSea, secondary: BridgeAIColors.copper.primary)
                ),
                .init(
                    title: "Trusted Escalation",
                    detail: "BridgeAI escalates quietly or assertively, sharing only the information you've approved with responders and loved ones.",
                    icon: "shield.lefthalf.fill",
                    accent: .init(primary: BridgeAIColors.cerulean.primary, secondary: BridgeAIColors.lavender)
                ),
                .init(
                    title: "Human-Centered Guidance",
                    detail: "Step-by-step coaching uses plain language, accessibility cues, and calming tone to keep panic low.",
                    icon: "heart.text.square",
                    accent: .init(primary: BridgeAIColors.copper.primary, secondary: BridgeAIColors.sunriseAccent)
                ),
                .init(
                    title: "Lifelong Learning",
                    detail: "Interactive lessons and family-friendly drills transform everyday routines into muscle memory for emergencies.",
                    icon: "graduationcap.fill",
                    accent: .init(primary: BridgeAIColors.moss.primary, secondary: BridgeAIColors.cerulean.primary)
                )
            ],
            capabilityGroups: [
                .assistiveSupport,
                .emergencyAutomation,
                .locationIntelligence,
                .courseLibrary
            ],
            courses: CourseModule.samples,
            supportResources: SupportResource.samples,
            trustedContacts: [
                .init(name: "Jordan Patel", relationship: "Partner", icon: "figure.stand") ,
                .init(name: "Mom", relationship: "Primary contact", icon: "person.fill"),
                .init(name: "Captain Ruiz", relationship: "Local fire marshal", icon: "figure.wave")
            ]
        )
    }
}

// MARK: - Data definitions
struct BridgeAIOverview {
    let appName: String
    let tagline: String
    let mission: String
    let introduction: String
    let pledge: String
}

struct MissionHighlight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let accent: BridgeAIGradientSwatch
}

struct CapabilityGroup: Identifiable {
    let id = UUID()
    let title: String
    let caption: String
    let context: String
    let icon: String
    let gradient: BridgeAIGradientSwatch
    let features: [CapabilityFeature]
    let cta: CapabilityAction?
}

struct CapabilityFeature: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
}

struct CapabilityAction {
    let label: String
    let detail: String
    let icon: String
}

struct CourseModule: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let duration: String
    let badge: String
    let icon: String
    let accent: BridgeAIGradientSwatch

    static let samples: [CourseModule] = [
        CourseModule(
            title: "Hands-On CPR & AED",
            description: "Master compressions, AED use, and choking response with animated walk-throughs and quick quizzes.",
            duration: "12 min",
            badge: "First Aid Essentials",
            icon: "hands.sparkles",
            accent: .init(primary: BridgeAIColors.cerulean.primary, secondary: BridgeAIColors.sunriseAccent)
        ),
        CourseModule(
            title: "Storm Ready Playbook",
            description: "Create a tornado, wildfire, and flood plan tailored to your location and household.",
            duration: "9 min",
            badge: "Disaster Readiness",
            icon: "cloud.bolt.rain.fill",
            accent: .init(primary: BridgeAIColors.copper.primary, secondary: BridgeAIColors.moss.primary)
        ),
        CourseModule(
            title: "Family Digital Safety",
            description: "Teach kids to spot misinformation, avoid scams, and activate Safe Word protocols.",
            duration: "6 min",
            badge: "Family Mode",
            icon: "lock.shield",
            accent: .init(primary: BridgeAIColors.deepSea, secondary: BridgeAIColors.lavender)
        )
    ]
}

struct SupportResource: Identifiable {
    let id = UUID()
    let label: String
    let detail: String
    let icon: String
    let tint: BridgeAIGradientSwatch

    static let samples: [SupportResource] = [
        SupportResource(
            label: "911 Dispatch",
            detail: "Direct emergency services with live GPS and incident notes.",
            icon: "phone.fill",
            tint: .init(primary: BridgeAIColors.cerulean.primary, secondary: BridgeAIColors.deepSea)
        ),
        SupportResource(
            label: "National Suicide & Crisis Lifeline",
            detail: "Call or text 988 for confidential emotional support 24/7.",
            icon: "heart.fill",
            tint: .init(primary: BridgeAIColors.moss.primary, secondary: BridgeAIColors.sunriseAccent)
        ),
        SupportResource(
            label: "FEMA Alerts",
            detail: "Verified alerts and shelter updates matched to your safe zones.",
            icon: "exclamationmark.triangle.fill",
            tint: .init(primary: BridgeAIColors.copper.primary, secondary: BridgeAIColors.sunriseAccent)
        ),
        SupportResource(
            label: "BridgeAI Command Center",
            detail: "Certified operators monitor silent mode activations when you're unable to respond.",
            icon: "dot.radiowaves.left.and.right",
            tint: .init(primary: BridgeAIColors.midnightAccent, secondary: BridgeAIColors.deepSea)
        )
    ]
}

struct TrustedContact: Identifiable {
    let id = UUID()
    let name: String
    let relationship: String
    let icon: String
}

// MARK: - Capability presets
extension CapabilityGroup {
    static let assistiveSupport = CapabilityGroup(
        title: "Assistive Guidance",
        caption: "AI coaching when danger is near but time remains.",
        context: "BridgeAI keeps you composed with calm, step-by-step plans tailored to the crisis you're facing.",
        icon: "person.fill.questionmark",
        gradient: .init(primary: BridgeAIColors.cerulean.primary, secondary: BridgeAIColors.sunriseAccent),
        features: [
            .init(
                title: "Health & Crisis Coach",
                detail: "Describe what you're seeing—BridgeAI responds with verified medical and safety steps in real time.",
                icon: "stethoscope"
            ),
            .init(
                title: "Disaster Playbooks",
                detail: "Tornado, wildfire, flood, or outage? Your plan updates instantly with FEMA and NOAA feeds.",
                icon: "wind"
            ),
            .init(
                title: "Smart Supply Cart",
                detail: "Build and track your household kits with expiration reminders and FEMA-backed recommendations.",
                icon: "cart"
            ),
            .init(
                title: "Calm Mode",
                detail: "Switch to a soothing voice, larger text, or voice commands to keep everyone grounded.",
                icon: "face.smiling.fill"
            )
        ],
        cta: .init(
            label: "Review preparedness checklist",
            detail: "See what BridgeAI suggests before storm season hits.",
            icon: "checkmark.seal.fill"
        )
    )

    static let emergencyAutomation = CapabilityGroup(
        title: "Emergency Automation",
        caption: "Immediate action when seconds decide survival.",
        context: "Whether you can shout for help or can’t make a sound, BridgeAI activates responders without delay.",
        icon: "bolt.fill",
        gradient: .init(primary: BridgeAIColors.copper.primary, secondary: BridgeAIColors.midnightAccent),
        features: [
            .init(
                title: "Assertive Voice Mode",
                detail: "Say \"Help me\" and BridgeAI dials emergency services, notifies contacts, and keeps you coached.",
                icon: "megaphone.fill"
            ),
            .init(
                title: "Silent Background Mode",
                detail: "Trigger with a power-button tap pattern or wearable. Location, audio, and alerts send without a sound.",
                icon: "hand.raised.fill"
            ),
            .init(
                title: "Evidence Capture",
                detail: "Optional encrypted audio/video snapshots support investigations and are deleted once you’re safe.",
                icon: "record.circle.fill"
            ),
            .init(
                title: "Safe Word Control",
                detail: "Cancel an accidental trigger or downgrade a response with a phrase only you know.",
                icon: "mouth.fill"
            )
        ],
        cta: .init(
            label: "Practice emergency triggers",
            detail: "Run a silent drill so every family member remembers the motions.",
            icon: "hand.tap.fill"
        )
    )

    static let locationIntelligence = CapabilityGroup(
        title: "Location Intelligence",
        caption: "Precision, privacy, and control for every incident.",
        context: "BridgeAI respects consent while keeping your responders informed until you confirm you're safe.",
        icon: "location.fill.viewfinder",
        gradient: .init(primary: BridgeAIColors.moss.primary, secondary: BridgeAIColors.deepSea),
        features: [
            .init(
                title: "Smart Escalation",
                detail: "BridgeAI checks taps, voice, and motion. If you can’t respond, it escalates automatically.",
                icon: "waveform"
            ),
            .init(
                title: "Invisible Tracking",
                detail: "Coordinates stream silently to authorities and loved ones—no on-screen clues for an aggressor.",
                icon: "eye.slash.fill"
            ),
            .init(
                title: "Safe Zone Alerts",
                detail: "Define home, school, and work. If you miss check-ins, your circle is notified with directions.",
                icon: "house.fill"
            ),
            .init(
                title: "Nearby Help Finder",
                detail: "See the nearest hospitals, shelters, and police stations with live hours and directions.",
                icon: "map"
            )
        ],
        cta: .init(
            label: "Update safe zones",
            detail: "Fine-tune radius, contacts, and auto-expire rules in under two minutes.",
            icon: "scope"
        )
    )

    static let courseLibrary = CapabilityGroup(
        title: "Courses & Drills",
        caption: "Turn bystanders into confident responders.",
        context: "Short lessons, realistic simulations, and shareable achievements keep safety top of mind year-round.",
        icon: "book.closed.fill",
        gradient: .init(primary: BridgeAIColors.deepSea, secondary: BridgeAIColors.lavender),
        features: [
            .init(
                title: "Micro-Lessons",
                detail: "Complete 2–5 minute bursts that fit between meetings, practices, and homework.",
                icon: "timer"
            ),
            .init(
                title: "Interactive Scenarios",
                detail: "Practice seizures, allergic reactions, and severe weather with branching decision paths.",
                icon: "square.grid.3x3.fill"
            ),
            .init(
                title: "Certification Track",
                detail: "Earn digital badges, and unlock FEMA or Red Cross-aligned certificates when you’re ready.",
                icon: "medal.fill"
            ),
            .init(
                title: "Family Mode",
                detail: "Kid-friendly stories teach 911 basics, Safe Words, and home evacuation routes.",
                icon: "person.3.fill"
            )
        ],
        cta: .init(
            label: "Schedule a family drill",
            detail: "Pick a weekend time and BridgeAI will deliver age-appropriate practice prompts.",
            icon: "calendar.badge.clock"
        )
    )
}

// MARK: - Gradient helpers
struct BridgeAIGradientSwatch {
    let primary: Color
    let secondary: Color

    func gradient(inset: Bool = false) -> LinearGradient {
        let start = inset ? primary.opacity(0.9) : primary
        let end = inset ? secondary.opacity(0.8) : secondary
        return LinearGradient(
            gradient: Gradient(colors: [start, end]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Palette
enum BridgeAIColors {
    static let background = Color(red: 1.0, green: 0.996, blue: 0.918)
    static let surfaceBackground = Color(red: 0.984, green: 0.976, blue: 0.932)
    static let title = Color(red: 0.239, green: 0.031, blue: 0.078)
    static let body = Color(red: 0.169, green: 0.274, blue: 0.317)
    static let bodySecondary = Color(red: 0.352, green: 0.431, blue: 0.466)
    static let shadow = Color(red: 0.239, green: 0.031, blue: 0.078)

    static let sunrise = BridgeAIGradientSwatch(
        primary: Color(red: 0.082, green: 0.376, blue: 0.478),
        secondary: Color(red: 0.239, green: 0.031, blue: 0.078)
    )
    static let sunriseAccent = Color(red: 0.318, green: 0.553, blue: 0.62)
    static let sunriseHighlight = Color(red: 0.918, green: 0.9, blue: 0.828)

    static let copper = BridgeAIGradientSwatch(
        primary: Color(red: 0.42, green: 0.11, blue: 0.18),
        secondary: Color(red: 0.27, green: 0.05, blue: 0.11)
    )
    static let moss = BridgeAIGradientSwatch(
        primary: Color(red: 0.11, green: 0.45, blue: 0.57),
        secondary: Color(red: 0.07, green: 0.31, blue: 0.43)
    )
    static let cerulean = BridgeAIGradientSwatch(
        primary: Color(red: 0.15, green: 0.56, blue: 0.69),
        secondary: Color(red: 0.09, green: 0.38, blue: 0.52)
    )
    static let deepSea = Color(red: 0.082, green: 0.376, blue: 0.478)
    static let lavender = Color(red: 0.988, green: 0.956, blue: 0.86)
    static let midnight = BridgeAIGradientSwatch(
        primary: Color(red: 0.2, green: 0.07, blue: 0.12),
        secondary: Color(red: 0.13, green: 0.03, blue: 0.08)
    )
    static let midnightAccent = Color(red: 0.29, green: 0.08, blue: 0.14)

    static func gradient(_ swatch: BridgeAIGradientSwatch) -> LinearGradient {
        swatch.gradient()
    }
}

private extension BridgeAIGradientSwatch {
    var primaryColor: Color { primary }
}

private extension Color {
    func gradient(inset: Bool) -> LinearGradient {
        let swatch = BridgeAIGradientSwatch(primary: self, secondary: self.opacity(0.75))
        return swatch.gradient(inset: inset)
    }
}
