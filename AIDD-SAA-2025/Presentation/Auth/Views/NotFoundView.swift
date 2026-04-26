import RxRelay
import SwiftUI

struct NotFoundView: View {

    let viewModel: NotFoundViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopNavigation()

                Spacer()

                ErrorStateView(
                    title: "notFound.title",
                    subtitle: "notFound.subtitle",
                    illustrationSystemName: "questionmark.circle",
                    primaryButtonTitle: "notFound.primaryButton",
                    onPrimaryTap: { viewModel.primaryTapped.accept(()) }
                )

                Spacer()
            }
        }
        .accessibilityIdentifier("NotFoundView")
    }
}
