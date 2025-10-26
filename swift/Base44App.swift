import SwiftUI
import Combine
import Charts
import UserNotifications
import Security
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Application entry point
@available(iOS 16.0, macOS 13.0, *)
@main
struct Base44MobileApp: App {
    @StateObject private var session = SessionController()
    @StateObject private var pushManager = PushNotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(pushManager)
                .task {
                    await session.bootstrap()
                    await pushManager.requestAuthorization()
                }
        }
    }
}

// MARK: - Root view and navigation orchestration
@available(iOS 16.0, macOS 13.0, *)
struct RootView: View {
    @EnvironmentObject private var session: SessionController

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ProgressView("Loading")
            case .needsLogin:
                LoginView()
            case .authenticated(_):
                DashboardContainerView()
            }
        }
        .animation(.default, value: session.phase)
    }
}

// MARK: - Session management
@MainActor
final class SessionController: ObservableObject {
    enum Phase: Equatable {
        case loading
        case needsLogin
        case authenticated(UserProfile)
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var token: AuthToken?

    private let api = Base44API()
    private let keychain = KeychainStore(service: "com.base44.mobile")

    func bootstrap() async {
        defer { if case .loading = phase { phase = .needsLogin } }
        do {
            if let storedToken: AuthToken = try keychain.read("authToken") {
                token = storedToken
                let profile = try await api.profile(token: storedToken)
                phase = .authenticated(profile)
            } else {
                phase = .needsLogin
            }
        } catch {
            print("Bootstrap error: \(error)")
            phase = .needsLogin
        }
    }

    func login(credentials: Credentials) async throws {
        phase = .loading
        do {
            let token = try await api.login(credentials: credentials)
            try keychain.store(token, key: "authToken")
            self.token = token
            let profile = try await api.profile(token: token)
            phase = .authenticated(profile)
        } catch {
            phase = .needsLogin
            throw error
        }
    }

    func logout() {
        token = nil
        try? keychain.delete("authToken")
        phase = .needsLogin
    }

    func refreshProfile() async {
        guard case .authenticated = phase, let token else { return }
        do {
            let profile = try await api.profile(token: token)
            phase = .authenticated(profile)
        } catch {
            print("Profile refresh failed: \(error)")
        }
    }
}

// MARK: - API layer
struct AuthToken: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

struct Credentials: Equatable {
    var email: String = ""
    var password: String = ""
}

struct UserProfile: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let avatarURL: URL?
}

struct Project: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let status: Status
    let updatedAt: Date

    enum Status: String, Codable, CaseIterable, Identifiable {
        case draft, active, paused, complete
        var id: String { rawValue }

        var tint: Color {
            switch self {
            case .draft: return .gray
            case .active: return .green
            case .paused: return .orange
            case .complete: return .blue
            }
        }
    }
}

struct TaskItem: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let dueDate: Date
    let completed: Bool
    let projectID: UUID
}

struct MetricPoint: Codable, Identifiable {
    let label: String
    let value: Double

    var id: String { label }
}

struct ActivityLogEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let action: String
    let performedBy: String
    let performedAt: Date
}

enum APIError: LocalizedError {
    case invalidURL
    case decodingFailed
    case unauthorized
    case server(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Base44 API URL is invalid."
        case .decodingFailed:
            return "Unable to parse the response from Base44."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .server(let message):
            return message
        }
    }
}

final class Base44API {
    private let baseURL = URL(string: "https://api.base44.com")
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }

    func login(credentials: Credentials) async throws -> AuthToken {
        let request = try request(
            path: "/auth/login",
            method: "POST",
            body: ["email": credentials.email, "password": credentials.password]
        )
        return try await send(request)
    }

    func profile(token: AuthToken) async throws -> UserProfile {
        var request = try request(path: "/me")
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    func projects(token: AuthToken) async throws -> [Project] {
        var request = try request(path: "/projects")
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    func tasks(token: AuthToken, projectID: UUID? = nil) async throws -> [TaskItem] {
        var components = URLComponents(url: try url(path: "/tasks"), resolvingAgainstBaseURL: false)
        if let projectID {
            components?.queryItems = [URLQueryItem(name: "projectId", value: projectID.uuidString)]
        }
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    func createTask(token: AuthToken, payload: TaskDraft) async throws -> TaskItem {
        var request = try request(path: "/tasks", method: "POST", body: payload)
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    func metrics(token: AuthToken) async throws -> [MetricPoint] {
        var request = try request(path: "/analytics/metrics")
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    func activity(token: AuthToken) async throws -> [ActivityLogEntry] {
        var request = try request(path: "/activity")
        request.addValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request)
    }

    // Generic request builders
    private func url(path: String) throws -> URL {
        guard let baseURL else { throw APIError.invalidURL }
        return baseURL.appendingPathComponent(path)
    }

    private func request(path: String, method: String = "GET", body: Encodable? = nil) throws -> URLRequest {
        let url = try url(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try jsonEncoder.encode(AnyEncodable(body))
        }
        return request
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.server(message: "Unexpected response")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try jsonDecoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decodingFailed
            }
        case 401:
            throw APIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.server(message: message)
        }
    }
}

struct TaskDraft: Codable {
    var title: String = ""
    var dueDate: Date = Date().addingTimeInterval(24 * 60 * 60)
    var projectID: UUID?

    init(title: String = "", dueDate: Date = Date().addingTimeInterval(24 * 60 * 60), projectID: UUID? = nil) {
        self.title = title
        self.dueDate = dueDate
        self.projectID = projectID
    }
}

private struct AnyEncodable: Encodable {
    private let encodeImpl: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeImpl = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}

// MARK: - View Models
@MainActor
final class LoginFormViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published private(set) var isValid: Bool = false
    @Published var error: LocalizedError?
    @Published private(set) var isSubmitting: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init() {
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                Self.validate(email: email, password: password)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isValid)
    }

    private static func validate(email: String, password: String) -> Bool {
        guard !email.isEmpty, email.contains("@"), password.count >= 8 else { return false }
        return true
    }

    func submit(using session: SessionController) async {
        guard isValid else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            error = nil
            try await session.login(credentials: Credentials(email: email, password: password))
        } catch {
            self.error = error as? LocalizedError ?? APIError.server(message: error.localizedDescription)
        }
    }

    func clearError() {
        error = nil
    }



}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var metrics: [MetricPoint] = []
    @Published private(set) var activity: [ActivityLogEntry] = []
    @Published var selectedProject: Project?
    @Published var isPresentingNewTask: Bool = false
    @Published var taskDraft = TaskDraft()
    @Published var error: LocalizedError?

    private let api: Base44API
    private let session: SessionController

    init(api: Base44API = Base44API(), session: SessionController) {
        self.api = api
        self.session = session
    }

    func reload() async {
        guard let token = session.token else { return }
        do {
            error = nil
            async let projects = api.projects(token: token)
            async let tasks = api.tasks(token: token, projectID: selectedProject?.id)
            async let metrics = api.metrics(token: token)
            async let activity = api.activity(token: token)
            self.projects = try await projects
            self.tasks = try await tasks
            self.metrics = try await metrics
            self.activity = try await activity
        } catch {
            self.error = error as? LocalizedError ?? APIError.server(message: error.localizedDescription)
        }
    }

    func saveTask() async {
        guard let token = session.token else { return }
        do {
            let created = try await api.createTask(token: token, payload: taskDraft)
            tasks.append(created)
            isPresentingNewTask = false
            taskDraft = TaskDraft(projectID: selectedProject?.id)
            error = nil
        } catch {
            self.error = error as? LocalizedError ?? APIError.server(message: error.localizedDescription)
        }
    }

    func clearError() {
        error = nil
    }

    func beginCreatingTask() {
        taskDraft = TaskDraft(projectID: selectedProject?.id)
        isPresentingNewTask = true
    }
}

// MARK: - Views
@available(iOS 16.0, macOS 13.0, *)
struct LoginView: View {
    @StateObject private var viewModel = LoginFormViewModel()
    @EnvironmentObject private var session: SessionController

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                }

                Section {
                    Button {
                        Task { await viewModel.submit(using: session) }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
            .navigationTitle("Base44 Login")
            .alert("Sign-in failed", isPresented: .constant(viewModel.error != nil)) {
                Button("Dismiss", role: .cancel) { viewModel.clearError() }
            } message: {
                Text(viewModel.error?.errorDescription ?? "Unknown error")
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct DashboardContainerView: View {
    @EnvironmentObject private var session: SessionController

    var body: some View {
        NavigationStack {
            DashboardView(session: session)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if case let .authenticated(profile) = session.phase {
                            ProfileMenu(profile: profile)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Refresh") { Task { await session.refreshProfile() } }
                    }
                }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct DashboardView: View {
    @ObservedObject var session: SessionController
    @StateObject private var viewModel: DashboardViewModel

    init(session: SessionController) {
        _session = ObservedObject(wrappedValue: session)
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metricsSection
                projectsSection
                tasksSection
                activitySection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .task { await viewModel.reload() }
        .onChange(of: session.token) { _ in Task { await viewModel.reload() } }
        .onChange(of: viewModel.selectedProject) { _ in Task { await viewModel.reload() } }
        .sheet(isPresented: $viewModel.isPresentingNewTask) {
            NewTaskForm(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("Dismiss", role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.error?.errorDescription ?? "Unknown error")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dashboard")
                    .font(.largeTitle.bold())
                Text("Monitor projects, tasks, and activity from Base44")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                viewModel.beginCreatingTask()
            } label: {
                Label("New Task", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var metricsSection: some View {
        GroupBox("Analytics") {
            if viewModel.metrics.isEmpty {
                Text("No metrics available yet.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(viewModel.metrics) { point in
                    BarMark(
                        x: .value("Metric", point.label),
                        y: .value("Value", point.value)
                    )
                }
                .chartYAxisLabel("Value")
                .frame(height: 180)
            }
        }
    }

    private var projectsSection: some View {
        GroupBox("Projects") {
            if viewModel.projects.isEmpty {
                Text("No projects found.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.projects) { project in
                        Button {
                            withAnimation { viewModel.selectedProject = project }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(project.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(project.status.rawValue.capitalized)
                                        .font(.caption.weight(.semibold))
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(project.status.tint.opacity(0.15), in: Capsule())
                                        .foregroundStyle(project.status.tint)
                                }
                                Text(project.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(project.updatedAt.formatted(.relative(presentation: .named)))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(viewModel.selectedProject?.id == project.id ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var tasksSection: some View {
        GroupBox("Tasks") {
            if viewModel.tasks.isEmpty {
                Text("No tasks scheduled.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.tasks) { task in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(task.title)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(task.completed ? Color.green : Color.secondary)
                            }
                            HStack(spacing: 8) {
                                Text(task.dueDate, style: .date)
                                    .font(.caption)
                                if let project = viewModel.projects.first(where: { $0.id == task.projectID }) {
                                    Text(project.name)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.secondary.opacity(0.08))
                        )
                    }
                }
            }
        }
    }

    private var activitySection: some View {
        GroupBox("Recent activity") {
            if viewModel.activity.isEmpty {
                Text("No recent actions.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(viewModel.activity.enumerated()), id: \.element.id) { index, entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.action)
                            .font(.subheadline)
                        HStack(spacing: 8) {
                            Text(entry.performedBy)
                                .font(.caption.weight(.medium))
                            Text(entry.performedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    if index != viewModel.activity.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ProfileMenu: View {
    let profile: UserProfile
    @EnvironmentObject private var session: SessionController

    var body: some View {
        Menu {
            Button("Refresh profile") { Task { await session.refreshProfile() } }
            Button("Sign out", role: .destructive) { session.logout() }
        } label: {
            HStack {
                if let avatarURL = profile.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    placeholder
                }
                Text(profile.name)
            }
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay(Text(String(profile.name.prefix(1))).font(.caption.bold()))
            .frame(width: 32, height: 32)
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct NewTaskForm: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $viewModel.taskDraft.title)
                    DatePicker("Due date", selection: $viewModel.taskDraft.dueDate, displayedComponents: .date)
                }

                Section("Project") {
                    Picker("Project", selection: $viewModel.taskDraft.projectID) {
                        Text("Unassigned").tag(UUID?.none)
                        ForEach(viewModel.projects) { project in
                            Text(project.name).tag(UUID?.some(project.id))
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.saveTask()
                            if viewModel.error == nil {
                                dismiss()
                            }
                        }
                    }
                        .disabled(viewModel.taskDraft.title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Platform services
final class PushNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
        } catch {
            await MainActor.run {
                self.authorizationStatus = .denied
            }
        }
#if canImport(UIKit)
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
#endif
    }
}

// MARK: - Keychain utilities
struct KeychainStore {
    let service: String

    func store<T: Codable>(_ value: T, key: String) throws {
        let data = try JSONEncoder().encode(value)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
    }

    func read<T: Codable>(_ key: String) throws -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
        guard let data = result as? Data else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }
}

enum KeychainError: Error {
    case unhandled(OSStatus)
}

// MARK: - Previews
@available(iOS 16.0, macOS 13.0, *)
struct Base44MobileApp_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(SessionController())
            .environmentObject(PushNotificationManager())
    }
}
