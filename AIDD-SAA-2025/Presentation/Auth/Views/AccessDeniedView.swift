import RxRelay
import SwiftUI

struct AccessDeniedView: View {

    let viewModel: AccessDeniedViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopNavigation(onBack: { viewModel.backTapped.accept(()) })

                Spacer()

                ErrorStateView(
                    title: "accessDenied.title",
                    subtitle: "accessDenied.subtitle",
                    illustrationSystemName: "person.crop.circle.badge.xmark",
                    primaryButtonTitle: "accessDenied.primaryButton",
                    onPrimaryTap: { viewModel.primaryTapped.accept(()) }
                )

                Spacer()
            }
        }
        .onAppear { viewModel.onAppear.accept(()) }
        .accessibilityIdentifier("AccessDeniedView")
    }
}
