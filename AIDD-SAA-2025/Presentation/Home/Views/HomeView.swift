import Combine
import RxRelay
import SwiftUI

/// Home screen — SAA 2025 tab root. PR-M2.3 wires US1 + US2:
/// header + hero + theme paragraph + Awards section + Kudos section.
/// FAB lands in US4; pull-to-refresh in US6.
///
/// Layout follows `design-style.md` §3 + §7 + §8 vertical anchor maps.
struct HomeView: View {

    @ObservedObject var state: HomeStateAdapter

    var onLanguageTap: () -> Void = {}
    var onSearchTap: () -> Void = {}
    var onNotificationsTap: () -> Void = {}
    /// Caller (RootView) handles router.reset for navigations emitted
    /// from `state.pendingNavigate`.
    var onNavigate: (AppRoute) -> Void = { _ in }
    /// Triggered when the user pulls to retry the awards section
    /// (US6 will replace this with a generic pull-to-refresh on the
    /// whole feed).
    var onRetryFeed: () -> Void = {}

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .top) {
                    // Layer 1: keyvisual + 4-stop gradient INSIDE the scroll
                    // content. 812 pt tall, anchored to the top of content
                    // — scrolls UP and out of view as the user scrolls
                    // down. After it scrolls away, only the solid dark
                    // `BrandOnCream` (set as ScrollView background below)
                    // remains, so the tab bar's frosted blur reads clean
                    // dark instead of bleeding keyvisual colours.
                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            Image("KeyvisualBackground")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 812)
                                .clipped()
                                .accessibilityHidden(true)

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
                            .frame(height: 200)
                            .accessibilityHidden(true)

                            // Bottom fade — blends keyvisual into dark over
                            // the last 200 pt so the boundary at y=812
                            // doesn't show a hard edge.
                            VStack(spacing: 0) {
                                Spacer()
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color(red: 0/255, green: 16/255, blue: 26/255).opacity(0.0), location: 0.0),
                                        .init(color: Color(red: 0/255, green: 16/255, blue: 26/255).opacity(1.0), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 200)
                            }
                            .frame(height: 812)
                            .accessibilityHidden(true)
                        }
                        Spacer(minLength: 0)
                    }

                    // Layer 2: foreground content — header + hero + theme +
                    // awards + kudos. Scrolls in front of the keyvisual.
                    contentStack(proxy: proxy)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollContentBackground(.hidden)
            .background(Color("BrandOnCream"))
            .refreshable {
                state.viewModel.pullToRefresh.accept(())
                for await refreshing in state.$isRefreshing.values where !refreshing {
                    break
                }
            }
            .onChange(of: state.pendingScrollTo) { anchor in
                guard let anchor else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(anchor, anchor: .top)
                }
                state.clearPendingScroll()
            }
        }
        // Solid dark behind everything (extends through TOP safe area to
        // sit beneath the keyvisual; bottom safe area is owned by
        // RootView's `safeAreaInset(.bottom) { BottomTabBar }` and must
        // NOT be overridden here — earlier .ignoresSafeArea() bled
        // ScrollView content past the tab bar's anchor.)
        .background(Color("BrandOnCream").ignoresSafeArea(edges: .top))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("HomeView")
        .onAppear { state.viewModel.viewAppeared.accept(()) }
        .onChange(of: state.pendingNavigate) { route in
            guard let route else { return }
            onNavigate(route)
            state.clearPendingNavigate()
        }
        .overlay(alignment: .bottomTrailing) {
            WriteKudoFAB(
                onCompose: { state.viewModel.fabComposeTapped.accept(()) },
                onKudosFeed: { state.viewModel.fabKudosFeedTapped.accept(()) }
            )
            .padding(.trailing, 20)
            .padding(.bottom, 16)
            .accessibilityIdentifier("HomeView.FAB")
        }
        .overlay(alignment: .topTrailing) {
            // US5 LanguagePickerDropdown — anchored under the chip in
            // the header. Tap-outside-dismiss layer + dropdown.
            ZStack(alignment: .topTrailing) {
                if state.isLanguagePickerPresented {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { state.isLanguagePickerPresented = false }
                        .accessibilityHidden(true)

                    LanguagePickerDropdown(
                        currentLanguage: state.selectedLanguage,
                        onSelect: { language in
                            state.viewModel.languageSelected.accept(language)
                            state.isLanguagePickerPresented = false
                        }
                    )
                    .padding(.trailing, 20)
                    .padding(.top, 56)  // chip y=64 → dropdown anchored just below
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topTrailing)))
                }
            }
            .animation(.easeOut(duration: 0.18), value: state.isLanguagePickerPresented)
        }
    }

    // MARK: - Content stack

    @ViewBuilder
    private func contentStack(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HomeHeader(
                language: state.selectedLanguage,
                hasUnreadNotifications: state.hasUnreadNotifications,
                onLanguage: { state.viewModel.languageTapped.accept(()) },
                onSearch: { state.viewModel.searchTapped.accept(()) },
                onNotifications: { state.viewModel.notificationsTapped.accept(()) }
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .id(HomeAnchor.top)

            Spacer().frame(height: 40)

            hero
                .padding(.horizontal, 20)

            Spacer().frame(height: 40)

            themeParagraph
                .padding(.horizontal, 20)

            Spacer().frame(height: 40)

            awardsSection
                .id(HomeAnchor.awards)

            Spacer().frame(height: 48)

            kudosSection
                .padding(.horizontal, 20)
                .id(HomeAnchor.kudos)

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 32) {
            Image("HeroLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 247, height: 109)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 24) {
                CountdownTimerView(
                    countdown: state.countdown,
                    showsComingSoon: state.showsComingSoon
                )

                eventInfo
            }

            aboutButtons
        }
    }

    // MARK: - Event info

    private var eventInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("home.event.time")
                    .font(.system(size: 14, weight: .light))
                    .tracking(0.25)
                    .foregroundStyle(.white)
                Text(formattedDate)
                    .font(.system(size: 18, weight: .regular))
                    .tracking(0.5)
                    .foregroundStyle(Color("BrandCream"))
            }

            HStack(spacing: 8) {
                Text("home.event.place")
                    .font(.system(size: 14, weight: .light))
                    .tracking(0.25)
                    .foregroundStyle(.white)
                Text(verbatim: "Âu Cơ Art Center")
                    .font(.system(size: 18, weight: .regular))
                    .tracking(0.5)
                    .foregroundStyle(Color("BrandCream"))
            }

            Text("home.event.livestream")
                .font(.system(size: 14, weight: .regular))
                .tracking(0.25)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale = Locale(identifier: "vi_VN")
        return f.string(from: Date(timeIntervalSince1970: 1_766_761_200))
    }

    // MARK: - ABOUT buttons

    private var aboutButtons: some View {
        HStack(spacing: 16) {
            Button(action: { state.viewModel.aboutAwardTapped.accept(()) }) {
                HStack(spacing: 8) {
                    Text("home.cta.aboutAward")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color("BrandOnCream"))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("BrandOnCream"))
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("BrandCream"))
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("HomeView.aboutAward")

            Button(action: { state.viewModel.aboutKudosTapped.accept(()) }) {
                HStack(spacing: 8) {
                    Text("home.cta.aboutKudos")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("BrandCream").opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color("DropdownBorder"), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("HomeView.aboutKudos")
        }
    }

    // MARK: - Theme paragraph

    private var themeParagraph: some View {
        Text("home.theme.note")
            .font(.system(size: 14, weight: .light))
            .tracking(0.25)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("HomeView.themeNote")
    }

    // MARK: - Awards section

    private var awardsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("home.awards.title")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white)
                Rectangle()
                    .fill(Color(red: 46/255, green: 57/255, blue: 64/255)) // #2E3940
                    .frame(height: 1)
                Text("home.awards.subtitle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color("BrandCream"))
            }
            .padding(.horizontal, 20)

            AwardCardsRow(
                state: state.awards,
                language: state.selectedLanguage,
                onCardTap: { kind in
                    state.viewModel.awardCardTapped.accept(kind)
                },
                onRetry: onRetryFeed
            )
            // Awards row is horizontal — leading edge inset 20pt, trailing
            // edge bleeds (1040pt). LazyHStack handles overflow.
            .padding(.leading, 20)
        }
    }

    // MARK: - Kudos section

    private var kudosSection: some View {
        KudosBannerView(
            state: state.kudosBanner,
            onDetailTap: { state.viewModel.kudosDetailTapped.accept(()) }
        )
    }
}
