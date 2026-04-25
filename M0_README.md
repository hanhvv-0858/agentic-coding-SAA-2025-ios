# M0 — Project Foundation (manual Xcode steps)

This README walks through the **5 things you must do in Xcode** to finish
M0 after the filesystem scaffold landed. Order matters — don't skip steps.

> **Why manual?** SPM packages, xcconfig wiring, and Info.plist keys
> require edits to `project.pbxproj` that are unsafe to automate from
> outside Xcode. The rest (folder structure, Swift sources, tests, CI,
> SwiftLint, gitignore) is already in place.

---

## Pre-flight

```sh
# from repo root
ls -la AIDD-SAA-2025/
# expect: App/ Core/ Domain/ Data/ Presentation/ Resources/ Assets.xcassets ContentView.swift
```

If those folders aren't visible, the synchronized-folder feature in
Xcode 15+ should pick them up automatically when you open the project.

---

## Step 1 — Add SwiftPM dependencies

In Xcode:

1. **File → Add Package Dependencies…**
2. Add each of the following (pin to exact version):

   | URL | Exact version |
   |-----|---------------|
   | `https://github.com/supabase/supabase-swift` | `2.30.0` (or latest stable on the day you add it) |
   | `https://github.com/ReactiveX/RxSwift` | `6.7.1` |

3. For `supabase-swift`, add these products to the **`AIDD-SAA-2025`** target:
   - `Supabase`

4. For `RxSwift`, add these products to the **`AIDD-SAA-2025`** target:
   - `RxSwift`
   - `RxRelay`
   - `RxCocoa`

5. For RxSwift, also add these to the **`AIDD-SAA-2025Tests`** target:
   - `RxSwift`
   - `RxRelay`
   - `RxTest`
   - `RxBlocking`

6. **Commit** `Package.resolved` to the repo.

> **Constitution V**: pin exact versions, never use ranges. CI relies on
> `Package.resolved` for reproducibility.

---

## Step 2 — Wire xcconfig files

1. Copy the template into 3 real config files (these are
   **gitignored** — never commit them):

   ```sh
   cp Config/Template.xcconfig Config/Dev.xcconfig
   cp Config/Template.xcconfig Config/Staging.xcconfig
   cp Config/Template.xcconfig Config/Prod.xcconfig
   ```

2. Open each one and replace `REPLACE_ME` placeholders with real values
   from the matching Supabase project.
3. In Xcode: **Project navigator → AIDD-SAA-2025 (project) → Info →
   Configurations**.
4. For the `Debug` configuration, set **Configuration Settings File =
   Dev** for both project and the `AIDD-SAA-2025` target. (You may want
   to duplicate `Debug` into `Staging` and `Release` configurations
   later; for now Dev is enough.)
5. For the `Release` configuration, set it to **Prod**.

---

## Step 3 — Inject xcconfig keys into Info.plist

The synchronized-folder Xcode 15 setup auto-generates `Info.plist`. Add
the following keys via **Project navigator → AIDD-SAA-2025 (target) →
Info → Custom iOS Target Properties** (or edit `Info.plist` directly if
visible):

| Key | Type | Value |
|-----|------|-------|
| `SUPABASE_URL` | String | `$(SUPABASE_URL)` |
| `SUPABASE_ANON_KEY` | String | `$(SUPABASE_ANON_KEY)` |
| `ALLOWED_EMAIL_DOMAINS` | String | `$(ALLOWED_EMAIL_DOMAINS)` |
| `OAUTH_REDIRECT_URL` | String | `$(OAUTH_REDIRECT_URL)` |
| `EVENT_TARGET_DATE` | String | `$(EVENT_TARGET_DATE)` |
| `EVENT_PLACE` | String | `$(EVENT_PLACE)` |
| `LIVE_STREAM_URL` | String | `$(LIVE_STREAM_URL)` |

> **Note**: `xcconfig` values that contain `//` need escaping (the
> template uses `/$()` as a marker — `AppConfig.load()` strips it on
> read). This is a known Xcode quirk.

Also register the **OAuth callback URL scheme** (M1 will use it, but set
it now):

- **Info → URL Types → Add**
- **URL Schemes**: `aidd-saa-2025`
- **Identifier**: `com.sun-asterisk.aidd-saa-2025.oauth`

---

## Step 4 — Add SwiftLint as a build phase

1. Install once:
   ```sh
   brew install swiftlint
   ```
2. In Xcode: **target `AIDD-SAA-2025` → Build Phases → "+" → New Run
   Script Phase**.
3. Move the new phase **above "Compile Sources"**.
4. Paste:
   ```sh
   if which swiftlint > /dev/null; then
     swiftlint --strict
   else
     echo "warning: SwiftLint not installed — brew install swiftlint"
   fi
   ```
5. Build the project. Fix any lint warnings. The CI also runs SwiftLint
   strictly (`.github/workflows/ci.yml`).

---

## Step 5 — Smoke test

1. Replace the contents of the boilerplate `ContentView.swift` body
   with this temporary smoke (just to verify config flows through):

   ```swift
   import SwiftUI

   struct ContentView: View {
       @EnvironmentObject private var bootstrap: BootstrapEnv

       var body: some View {
           VStack(spacing: 12) {
               Text("Bootstrap OK").font(.title2)
               Text("Supabase: \(bootstrap.container.config.supabaseURL.absoluteString)")
               Text("Allowlist: \(bootstrap.container.config.allowedEmailDomains.sorted().joined(separator: ", "))")
                   .font(.footnote)
           }
           .padding()
       }
   }

   #Preview { ContentView().environmentObject(BootstrapEnv(container: try! Container.bootstrap())) }
   ```

   *(This is throwaway — M1 replaces `ContentView` with the routed root
   view consuming `AppRouter`.)*

2. Run on the simulator. You should see the Supabase URL and the
   allowlist printed.

3. Run tests:
   ```sh
   xcodebuild test \
     -project AIDD-SAA-2025.xcodeproj \
     -scheme AIDD-SAA-2025 \
     -destination "platform=iOS Simulator,name=iPhone 15"
   ```
   Expected: `AllowedEmailDomainsTests`, `AppLanguageTests`,
   `LocaleStoreTests` all pass.

---

## M0 acceptance — tick before merging the PR

- [ ] App builds Debug + Release without code-signing on simulator
- [ ] `xcodebuild test` runs and the 3 Core test classes pass
- [ ] SwiftLint reports 0 warnings (`swiftlint --strict` exit 0)
- [ ] `Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL")`
      returns a non-nil string at runtime
- [ ] `git status` shows: no `Config/Dev.xcconfig`,
      `Config/Staging.xcconfig`, `Config/Prod.xcconfig` tracked
- [ ] `grep -r "service_role\|SERVICE_ROLE_KEY" .` returns no matches
      in committed sources
- [ ] CI green on the PR

When all boxes are ticked, the foundation is ready and **M1 (Authentication)
can begin**.

---

## What the scaffold added (file-by-file)

| Path | Purpose |
|------|---------|
| `.gitignore` | Xcode + xcconfig + IDE noise |
| `.swiftlint.yml` | Lint rules per constitution |
| `.github/workflows/ci.yml` | Build + test + lint + secrets check |
| `Config/Template.xcconfig` | Template for the 3 env xcconfigs |
| `AIDD-SAA-2025/App/AIDD_SAA_2025App.swift` | App entry — wired to `Container.bootstrap()` |
| `AIDD-SAA-2025/Core/Logger.swift` | OSLog wrapper, 4 named loggers |
| `AIDD-SAA-2025/Core/Config/AppConfig.swift` | Reads & validates Info.plist keys |
| `AIDD-SAA-2025/Core/DI/Container.swift` | DI composition root |
| `AIDD-SAA-2025/Domain/Entities/AppLanguage.swift` | `vi` / `en` enum + device-locale default |
| `AIDD-SAA-2025/Domain/Entities/AllowedEmailDomains.swift` | Domain check (case-insensitive, whitespace-trimming) |
| `AIDD-SAA-2025/Domain/Entities/AuthSession.swift` | Session value + `AuthUser` with `emailDomain` accessor |
| `AIDD-SAA-2025/Domain/Stores/AuthStore.swift` | `AuthState` BehaviorRelay (`.unknown` / `.signedOut` / `.signedIn`) |
| `AIDD-SAA-2025/Domain/Stores/LocaleStore.swift` | Persisted `AppLanguage` BehaviorRelay |
| `AIDD-SAA-2025/Presentation/Shared/Navigation/AppRoute.swift` | All routable destinations + `NotFoundSource` + `ProfileAnchor` |
| `AIDD-SAA-2025/Presentation/Shared/Navigation/AppTab.swift` | 4-tab enum |
| `AIDD-SAA-2025/Presentation/Shared/Navigation/AppRouter.swift` | Root-route BehaviorRelay |
| `AIDD-SAA-2025Tests/Core/AllowedEmailDomainsTests.swift` | 6 unit tests |
| `AIDD-SAA-2025Tests/Core/AppLanguageTests.swift` | 2 unit tests |
| `AIDD-SAA-2025Tests/Core/LocaleStoreTests.swift` | 4 unit tests with isolated `UserDefaults` suite |

---

## Troubleshooting

**Build fails: `No such module 'RxSwift'`**
→ Step 1 wasn't done. Add the SPM packages.

**Build fails: `Configuration error` / `AppConfig: missing or invalid Info.plist key 'SUPABASE_URL'`**
→ Either Step 2 (xcconfig wiring) or Step 3 (Info.plist keys) didn't
land. Run the simulator and read the on-screen error message — it tells
you which key is missing.

**`Package.resolved` is git-ignored**
→ It's in the path `AIDD-SAA-2025.xcodeproj/project.xcworkspace/xcshareddata/`
or `swiftpm/`. Force-add it:
```sh
git add -f AIDD-SAA-2025.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

**Synchronized folder didn't pick up new files**
→ Right-click the project root in Xcode → "Refresh Folder".

---

## Post-M0 — what's next

After all M0 acceptance items are ticked, see
[.momorph/contexts/IMPLEMENTATION_ROADMAP.md](.momorph/contexts/IMPLEMENTATION_ROADMAP.md)
for **M1 — Authentication** which builds on this foundation:

- `AuthRepository` protocol + `SupabaseAuthDataSource` impl
- Login + Access denied + Not Found views
- `LanguagePickerSheet`, `ErrorStateView`, shared TopNavigation
- 4 user stories, 6 success criteria

Spec: [.momorph/specs/8HGlvYGJWq-authentication/spec.md](.momorph/specs/8HGlvYGJWq-authentication/spec.md)
