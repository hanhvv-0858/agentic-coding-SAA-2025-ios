# iOS Frontend Guidelines — SwiftUI + RxSwift

This document is the runtime guide for day-to-day frontend work on the
AIDD-SAA-2025 iOS app. It implements, not replaces, the project constitution
at `.momorph/constitution.md` (Principles I–V). When this guide conflicts with
the constitution, the constitution wins.

---

## 1. Source Layout (Clean Architecture — Principle I)

```
AIDD-SAA-2025/
├── App/                      # App entry, DI composition root
│   └── AIDD_SAA_2025App.swift
├── Presentation/
│   ├── <Feature>/
│   │   ├── Views/            # SwiftUI Views (declarative, state-driven)
│   │   ├── ViewModels/       # Rx-based ViewModels
│   │   └── Components/       # Feature-local reusable subviews
│   └── Shared/               # Cross-feature views, modifiers, styles
├── Domain/
│   ├── Entities/             # Plain Swift structs; no framework imports
│   ├── UseCases/             # Single-responsibility business operations
│   └── Repositories/         # Protocol definitions only
├── Data/
│   ├── Repositories/         # Protocol implementations
│   ├── Remote/               # Supabase clients, DTOs, mappers
│   └── Local/                # Keychain, disk cache, CoreData (if any)
├── Core/
│   ├── DI/                   # Resolver / Factory setup
│   ├── Extensions/           # Foundation / SwiftUI / Rx extensions
│   └── Utilities/            # Logger, Clock, formatters
└── Resources/
    ├── Assets.xcassets
    └── Localizable.xcstrings
```

Rules:

- One primary type per file. File name matches the type.
- No import of `Supabase` or `RxSwift` in `Domain/` or SwiftUI View files.
- `Presentation/` may import `RxSwift` only inside ViewModels — Views bind
  through a published-state bridge.

---

## 2. SwiftUI Conventions (Principle II)

- Use `@StateObject` for ViewModel ownership at the top of a screen; use
  `@ObservedObject` only for injected collaborators.
- Keep Views dumb: every conditional in the body comes from a ViewModel
  property. If a View has more than one `if let` branching UI layout,
  extract a child view.
- Prefer SwiftUI navigation primitives: `NavigationStack` + value-typed
  routes. Do NOT use `UIHostingController` push/present unless bridging into
  existing UIKit.
- Respect safe areas with `.safeAreaInset`, not hard-coded padding.
- Use semantic colors (`.primary`, `.secondary`, custom from asset catalog
  with light/dark variants). No `Color(red: …)` literals in view code.
- Typography via `.font(.body)`, `.font(.title2)`, etc. — Dynamic Type
  MUST work. Test at `AX5` size on every P1 screen.
- Animations: use `withAnimation(.spring)` / `.easeInOut(duration:)`. Keep
  durations ≤ 350 ms unless there is a specific UX reason.

### Accessibility (mandatory)

Every interactive element requires one of:

```swift
.accessibilityLabel("Sign in")
.accessibilityHint("Signs you into your account")
.accessibilityAddTraits(.isButton)
```

Touch targets MUST be ≥ 44×44 pt (`.frame(minWidth: 44, minHeight: 44)` on
icon-only buttons).

### Localization

```swift
Text("welcome.title")                // resolves from Localizable.xcstrings
Text("greeting.\(userName)")         // interpolations — keep the format key stable
```

No hard-coded user-facing English strings in view code.

---

## 3. RxSwift Conventions (Principle III)

### ViewModel shape

```swift
protocol SignInViewModel {
    // Inputs
    var emailInput: PublishRelay<String> { get }
    var passwordInput: PublishRelay<String> { get }
    var signInTapped: PublishRelay<Void> { get }

    // Outputs
    var isLoading: Driver<Bool> { get }
    var errorMessage: Signal<String> { get }
    var navigateHome: Signal<Void> { get }
}
```

Rules:

- Inputs use `PublishRelay` / `BehaviorRelay`. Outputs use `Driver` / `Signal`
  (UI-safe, replay semantics, no-throw).
- Every `subscribe`, `bind(to:)` stores its `Disposable` in `self.disposeBag`.
- Explicit schedulers at layer boundaries:
  - Network / disk work: `.observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))`
  - UI updates: `.observe(on: MainScheduler.instance)`
- Never create a `DispatchQueue.main.async` inside Rx chains — use the
  scheduler API.
- Use `.materialize()` to test error paths; never swallow errors with
  `.catchAndReturn(nil)` unless the rationale is in a code comment.

### View ↔ ViewModel binding

A single adapter per screen converts Rx outputs to SwiftUI state:

```swift
@MainActor
final class SignInStateAdapter: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    // ...
    init(viewModel: any SignInViewModel) {
        viewModel.isLoading.drive(onNext: { [weak self] in self?.isLoading = $0 })
            .disposed(by: disposeBag)
        // ...
    }
}
```

Views consume only `@StateObject private var state: SignInStateAdapter` —
Views never import `RxSwift`.

---

## 4. Dependency Injection

- Composition root is in `App/`. Lower layers receive dependencies by
  initializer — no service locator, no singletons for business logic.
- Allowed singletons: `Logger`, `Date()`/`Clock`, and the configured
  `SupabaseClient` instance (created once at app launch).
- Use `protocol` + `struct`/`final class` implementation so tests can
  substitute fakes.

---

## 5. Assets & Resources

- Image assets: SVG (rendered as template) or PDF preferred; PNG only when
  raster is required. Provide 1x/2x/3x in `Assets.xcassets`.
- Filenames: `snake_case` in asset catalog names, matching the SwiftUI call
  `Image("sign_in_hero")`.
- SF Symbols first — every screen should exhaust SF Symbols before shipping
  a custom icon.
- Color assets: define in `Assets.xcassets` as `Color Set` with Any/Dark
  appearance pair. Reference via `Color("BrandPrimary")`.

---

## 6. Navigation

All navigation decisions MUST trace back to the screen flow doc at
`.momorph/contexts/SCREENFLOW.md` (when present) or the relevant feature
spec. No guessed destinations. Use typed route values:

```swift
enum AppRoute: Hashable {
    case signIn
    case home
    case profile(userId: UUID)
}

NavigationStack(path: $router.path) {
    RootView()
        .navigationDestination(for: AppRoute.self) { route in
            switch route { /* ... */ }
        }
}
```

Router logic sits in the Presentation layer and is driven by ViewModel
output `Signal`s.

---

## 7. Testing (Principle IV)

- **Unit tests** live in `AIDD-SAA-2025Tests/` mirroring the source tree.
- ViewModel tests MUST use `RxTest.TestScheduler` — no real clock, no real
  network.
- Assertion style:

  ```swift
  let scheduler = TestScheduler(initialClock: 0)
  let observer = scheduler.createObserver(Bool.self)
  sut.isLoading.drive(observer).disposed(by: bag)
  scheduler.createColdObservable([.next(10, ())]).bind(to: sut.signInTapped).disposed(by: bag)
  scheduler.start()
  XCTAssertEqual(observer.events, [.next(10, true), .next(20, false)])
  ```

- **UI tests** in `AIDD-SAA-2025UITests/` cover every P1 acceptance
  scenario from the feature spec. Use accessibility identifiers, never
  label text, for locators (they survive localization).
- Tests MUST be written **before** the implementation for Domain and
  ViewModel code (constitution IV).

---

## 8. Linting & Formatting

- SwiftLint config lives at repo root (`.swiftlint.yml`). Warnings fail CI.
- Prefer trailing commas in multi-line collection literals for diff
  friendliness.
- Line length: 120 columns soft, 140 hard.
- Imports sorted alphabetically, grouped: system → third-party → first-
  party (separated by blank lines).
