import RxRelay
import SwiftUI

/// Implements the Login screen per `design-style.md` for screen
/// `8HGlvYGJWq`. All sizes / spacings / colors / typography are
/// derived from that document — see it for canonical values.
///
/// **Layout pattern**: the main content `VStack` is the primary view
/// (respects safe area). The keyvisual + top-fade gradient are
/// applied via `.background(...) { … .ignoresSafeArea() }` so they
/// extend behind the status bar / Dynamic Island without forcing the
/// content stack itself to draw under the status bar (which is what
/// happens when both layers are siblings in a ZStack and the bg uses
/// `.ignoresSafeArea()` — SwiftUI grows the ZStack frame to match,
/// pulling the content stack along with it).
struct LoginView: View {

    @ObservedObject var state: LoginStateAdapter

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)        // logo y = safe-area + 8 (matches design y=52)

            Spacer().frame(height: 156)  // header content end → hero (252 − 96)

            hero
                .padding(.horizontal, 20)

            Spacer().frame(height: 32)   // hero → welcome (393 − 361)

            welcomeText
                .padding(.horizontal, 20)

            // Flex space — design = 193pt; absorbs device-height
            // delta on iPhone 17+ (taller than the 812pt baseline).
            Spacer(minLength: 100)

            signInButton                 // 246 × 40 pt, centered
                .frame(width: 246)

            Spacer().frame(height: 114)  // CTA → footer (780 − 666)

            footer
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alignment: .top) {
            // Keyvisual + top-fade gradient. Both extend through the
            // status bar; the foreground content stack above stays
            // within safe area.
            ZStack(alignment: .top) {
                Image("KeyvisualBackground")
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)

                // Canonical 4-stop gradient per Figma color picker
                // (#00101A, alphas 1.0 / 0.9 / 0.6 / 0.0, evenly
                // distributed). The `list_frame_styles` MCP earlier
                // returned a 7-stop CSS approximation — superseded
                // by this design-source-verified version.
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0/255, green: 16/255, blue: 26/255).opacity(1.00), location: 0.0),
                        .init(color: Color(red: 0/255, green: 16/255, blue: 26/255).opacity(0.90), location: 1.0/3.0),
                        .init(color: Color(red: 0/255, green: 16/255, blue: 26/255).opacity(0.60), location: 2.0/3.0),
                        .init(color: Color(red: 0/255, green: 16/255, blue: 26/255).opacity(0.00), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)      // covers safe-area-top + 60pt visible band on every device
                .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            // Tap-outside-to-dismiss layer + anchored language picker.
            // Both live inside the safe area (no .ignoresSafeArea()) so
            // the dropdown sits below the chip at the correct y.
            ZStack(alignment: .topTrailing) {
                if state.isLanguageSheetPresented {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { state.isLanguageSheetPresented = false }
                        .accessibilityHidden(true)

                    LanguagePickerDropdown(
                        currentLanguage: state.selectedLanguage,
                        onSelect: { language in
                            state.viewModel.languageSelected.accept(language)
                            state.isLanguageSheetPresented = false
                        }
                    )
                    .padding(.trailing, 20)
                    .padding(.top, 56)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
                }
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { state.alertMessage != nil },
                set: { presented in if !presented { state.alertMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(state.alertMessage ?? "") }
        )
        .animation(.easeOut(duration: 0.18), value: state.isLanguageSheetPresented)
        .onAppear { state.viewModel.viewAppeared.accept(()) }
    }

    // MARK: - Subviews

    /// Header per design §3.2: brand logo (48×44) at left edge, language
    /// chip (90×32) at right edge. Per Figma, logo top is at y=52 and
    /// chip top is at y=64 — a 12 pt offset captured via the chip's
    /// `.padding(.top, 12)`.
    private var header: some View {
        HStack(alignment: .top, spacing: 0) {
            Image("BrandLogoSmall")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 44)
                .accessibilityHidden(true)

            Spacer(minLength: 0)

            LanguageSwitcherChip(
                language: state.selectedLanguage,
                action: { state.viewModel.languageTapped.accept(()) }
            )
            .padding(.top, 12)   // chip y=64 vs logo y=52 (Δ = 12)
        }
        .frame(height: 44)       // matches logo height (largest in row)
    }

    /// Hero wordmark — design §3.4. PNG anchored to left edge, NOT
    /// centered. 247 × 109 pt at design baseline.
    private var hero: some View {
        Image("HeroLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 247)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)
    }

    /// Welcome copy — design §2 (14 pt / Montserrat 300 / line-h 20 /
    /// letter-spacing +0.25 / left-aligned / pure white).
    private var welcomeText: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(localized("login.welcome.title"))
                .font(.system(size: 14, weight: .light))
                .tracking(0.25)
                .lineSpacing(6)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Text(localized("login.welcome.subtitle"))
                .font(.system(size: 14, weight: .light))
                .tracking(0.25)
                .lineSpacing(6)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Sign-in CTA — design §3.6.
    /// Width 246 / height 40 / radius 4 / cream bg / 14 pt 500 label
    /// then 24 pt full-color Google G icon.
    private var signInButton: some View {
        Button(action: { state.viewModel.signInTapped.accept(()) }) {
            HStack(spacing: 8) {
                Text(localized("login.cta"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("BrandOnCream"))

                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                        .tint(Color("BrandOnCream"))
                } else {
                    Image("GoogleG")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("BrandCream").opacity(state.isLoading ? 0.7 : 1.0))
            )
        }
        .buttonStyle(.plain)
        .disabled(state.isLoading)
        .accessibilityIdentifier("LoginView.signInButton")
        .accessibilityLabel(Text("login.cta.accessibilityLabel"))
        .accessibilityAddTraits(.isButton)
    }

    /// Footer — design §3.7 (12 pt / Montserrat 400 / center / pure white).
    private var footer: some View {
        Text("login.copyright")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityIdentifier("LoginView.footer")
    }

    private func localized(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        let template = String(localized: key)
        if args.isEmpty { return template }
        return String(format: template, arguments: args)
    }
}
