import Combine
import Foundation
import RxCocoa
import RxRelay
import RxSwift

/// SwiftUI bridge for `LoginViewModel`. Subscribes to the Rx outputs
/// once and republishes them via `@Published` so the View can use plain
/// `@StateObject`. Per Constitution Principle III, this is the only
/// type in the auth feature that imports `Combine`.
final class LoginStateAdapter: ObservableObject {

    @Published private(set) var isLoading = false
    @Published private(set) var selectedLanguage: AppLanguage = .en
    @Published var alertMessage: String?
    @Published var isLanguageSheetPresented = false

    let viewModel: LoginViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel

        viewModel.isLoading
            .drive(onNext: { [weak self] in self?.isLoading = $0 })
            .disposed(by: disposeBag)

        viewModel.selectedLanguage
            .drive(onNext: { [weak self] in self?.selectedLanguage = $0 })
            .disposed(by: disposeBag)

        viewModel.errorMessage
            .emit(onNext: { [weak self] in self?.alertMessage = $0 })
            .disposed(by: disposeBag)

        viewModel.presentLanguageSheet
            .emit(onNext: { [weak self] in self?.isLanguageSheetPresented = true })
            .disposed(by: disposeBag)
    }
}
