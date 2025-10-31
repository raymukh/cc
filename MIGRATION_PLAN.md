# Base44 Web-to-Swift Migration Notes

## 1. API Interaction Audit

The current repository snapshot does not include the compiled React source files under `src/`, so concrete call sites for `@base44/sdk` or bespoke fetch helpers are unavailable. The only reliable references that remain are the package metadata and SDK documentation shipped in `node_modules`. Based on `package.json`, the project depends directly on `@base44/sdk` along with `react-hook-form`, `zod`, and `react-router-dom`. Before starting the Swift migration, recover the missing React source tree (for example by checking the upstream repository or restoring from backup) so that the exact REST resources, query parameters, and mutation flows can be catalogued.

Once the JavaScript sources are available, enumerate:

- All imports from `@base44/sdk` and the specific client methods invoked.
- Any custom wrappers around `fetch`, `axios`, or SDK helpers that layer business logic (authentication headers, retry logic, pagination, etc.).
- Validation schemas authored with `zod` that enforce payload shapes.

Document the inputs/outputs of each call so their equivalents can be recreated using Swift's networking primitives.

## 2. Native Project Scaffolding

1. Create a new Xcode project using the **App** template with SwiftUI lifecycle.
2. Adopt Swift Package Manager (SPM) as the primary dependency tool. Mirror the JavaScript capabilities by adding:
   - **Authentication**: If the Base44 SDK exposes OAuth flows, pull in packages such as `ASWebAuthenticationSession` wrappers or community OAuth libraries.
   - **Charts**: Add `Charts` (Apple framework) or third-party equivalents like `SwiftUICharts` if feature parity requires.
3. When a library is not available through SPM, integrate CocoaPods as a secondary manager (configure an `.xcworkspace` and `Podfile`). Keep SwiftUI views in the main target while bridging UIKit-only pods as needed.

## 3. Data Layer Port

- **Direct REST**: Prefer reimplementing API calls with `URLSession` and async/await. Encapsulate endpoints inside a `Base44Service` struct/class that exposes async methods mirroring the SDK surface area. Use `Codable` models to serialize/deserialize payloads.
- **Bridge Approach**: If the JavaScript SDK contains non-trivial logic (e.g., cryptography, complex auth flows) that is hard to reproduce, consider hosting the Node SDK in a lightweight service (e.g., Vapor or Express running locally) and communicate via HTTP/WebSockets. This should be a temporary measure until a pure Swift implementation exists.
- **HTTP Client Enhancements**: For higher throughput or streaming endpoints, integrate `AsyncHTTPClient` (via SwiftNIO) and wrap responses into Swift Concurrency-friendly APIs.

## 4. UI Modeling in SwiftUI

- Map each React route/component to a SwiftUI `NavigationStack` hierarchy. Lists and tables become `List` views, forms become `Form`, and charts convert to `Charts` or custom drawing code.
- Recreate reusable UI atoms (buttons, cards, badges) as SwiftUI `View`s or `ViewModifier`s. Translate Tailwind design tokens from `tailwind.config.js` into shared constants (color palette, spacing scale, typography) using extensions on `Color`, `Font`, and `EdgeInsets`.

## 5. Validation Strategy

- Convert `zod` schemas into Swift structs with validation logic using result builders or Combine pipelines. Evaluate libraries like `swift-validated` or implement a custom `ValidationRule` protocol so constraints remain composable.
- Ensure client-side validation errors mirror existing UX by surfacing `LocalizedError` values in forms and disabling submission buttons via state bindings.

## 6. Navigation and Dialog Replacement

- Replace React Router and Radix dialogs with SwiftUI equivalents: nested `NavigationStack`s for deep links, `.sheet` for modals, `.alert` for confirmations, and `.popover` for contextual overlays.
- Manage state with `@State`, `@StateObject`, and `@EnvironmentObject`. Share session/authentication state through an `ObservableObject` injected at the root scene.

## 7. Platform Integrations

- Store sensitive tokens in the Keychain using `KeychainAccess` or native APIs.
- Wire up Push Notifications via `UNUserNotificationCenter` and register device tokens with Base44 if required.
- Schedule background sync tasks using `BGTaskScheduler` for periodic data refreshes.
- Investigate Base44-specific native features (biometrics, offline caching) and map them to appropriate iOS frameworks.

## 8. Testing Plan

- Author unit tests with `XCTest` covering networking clients (mocking `URLProtocol`) and validation logic.
- Create `XCUITest` suites for core user journeys (authentication, CRUD operations, charts dashboards).
- Maintain parity with the existing web regression tests before sunset by comparing payloads and ensuring UI state matches the React implementation.

## Next Steps

1. Restore or obtain the missing React source directory to complete the API audit.
2. Draft a detailed endpoint inventory and data contract document.
3. Spike a prototype SwiftUI screen that exercises one Base44 endpoint end-to-end.

These notes can evolve into a full migration runbook once the JavaScript codebase is fully accessible.
