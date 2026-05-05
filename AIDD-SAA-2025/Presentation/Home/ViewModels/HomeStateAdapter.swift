import Combine
import Foundation
import RxCocoa
import RxRelay
import RxSwift

/// SwiftUI bridge for `HomeViewModel`. Subscribes to Rx outputs and
/// republishes via `@Published`. Per Constitution III, this is the
/// only type in the Home feature that imports `Combine`.
final class HomeStateAdapter: ObservableObject {

    // US1
    @Published private(set) var countdown: CountdownVM = CountdownVM(days: 0, hours: 0, minutes: 0)
    @Published private(set) var showsComingSoon: Bool = true
    @Published private(set) var selectedLanguage: AppLanguage = AppLanguage.default

    // US2
    @Published private(set) var awards: AwardsTeaserState = .loading
    @Published private(set) var kudosBanner: KudosBannerState = .loading

    // US3
    @Published private(set) var hasUnreadNotifications: Bool = false

    // US5
    @Published var isLanguagePickerPresented: Bool = false

    // US6
    @Published private(set) var isRefreshing: Bool = false

    // Navigation + scroll signals — re-emitted via @Published one-shot
    // values so the View can react via `.onChange`.
    @Published private(set) var pendingNavigate: AppRoute?
    @Published private(set) var pendingScrollTo: HomeAnchor?

    let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel

        viewModel.countdown
            .drive(onNext: { [weak self] in self?.countdown = $0 })
            .disposed(by: disposeBag)

        viewModel.showsComingSoon
            .drive(onNext: { [weak self] in self?.showsComingSoon = $0 })
            .disposed(by: disposeBag)

        viewModel.selectedLanguage
            .drive(onNext: { [weak self] in self?.selectedLanguage = $0 })
            .disposed(by: disposeBag)

        viewModel.awards
            .drive(onNext: { [weak self] in self?.awards = $0 })
            .disposed(by: disposeBag)

        viewModel.kudosBanner
            .drive(onNext: { [weak self] in self?.kudosBanner = $0 })
            .disposed(by: disposeBag)

        viewModel.hasUnreadNotifications
            .drive(onNext: { [weak self] in self?.hasUnreadNotifications = $0 })
            .disposed(by: disposeBag)

        viewModel.isRefreshing
            .drive(onNext: { [weak self] in self?.isRefreshing = $0 })
            .disposed(by: disposeBag)

        viewModel.navigate
            .emit(onNext: { [weak self] route in self?.pendingNavigate = route })
            .disposed(by: disposeBag)

        viewModel.scrollTo
            .emit(onNext: { [weak self] anchor in self?.pendingScrollTo = anchor })
            .disposed(by: disposeBag)

        viewModel.presentLanguagePicker
            .emit(onNext: { [weak self] in self?.isLanguagePickerPresented = true })
            .disposed(by: disposeBag)
    }

    /// Called by the View after consuming a navigation event so the
    /// next emission can re-trigger `.onChange`.
    func clearPendingNavigate() { pendingNavigate = nil }

    /// Called by the View after scrolling to an anchor.
    func clearPendingScroll() { pendingScrollTo = nil }
}
