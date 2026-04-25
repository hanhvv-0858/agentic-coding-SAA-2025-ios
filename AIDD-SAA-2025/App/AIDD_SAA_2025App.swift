import Combine
import os
import SwiftUI

@main
struct AIDD_SAA_2025App: App {
    private let bootstrap: BootstrapResult = AIDD_SAA_2025App.makeBootstrap()

    var body: some Scene {
        WindowGroup {
            switch bootstrap {
            case .ready(let container):
                ContentView()
                    .environmentObject(BootstrapEnv(container: container))
            case .failure(let error):
                BootstrapErrorView(error: error)
            }
        }
    }

    private static func makeBootstrap() -> BootstrapResult {
        do {
            let container = try Container.bootstrap()
            return .ready(container)
        } catch {
            Log.app.error("Bootstrap failed: \(String(describing: error), privacy: .public)")
            return .failure(error)
        }
    }
}

private enum BootstrapResult {
    case ready(Container)
    case failure(Error)
}

final class BootstrapEnv: ObservableObject {
    let container: Container
    init(container: Container) { self.container = container }
}

private struct BootstrapErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Configuration error")
                .font(.title2)
                .accessibilityAddTraits(.isHeader)
            Text(String(describing: error))
                .font(.body.monospaced())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
