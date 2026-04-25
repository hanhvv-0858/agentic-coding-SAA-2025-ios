//
//  ContentView.swift
//  AIDD-SAA-2025
//
//  Created by vu.van.hanh on 4/24/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var bootstrap: BootstrapEnv

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("✅ Bootstrap OK").font(.title2).bold()

            Group {
                row("Supabase URL", bootstrap.container.config.supabaseURL.absoluteString)
                row("Allowlist", bootstrap.container.config.allowedEmailDomains.sorted().joined(separator: ", "))
                row("Event date", bootstrap.container.config.eventTargetDate.formatted())
                row("OAuth redirect", bootstrap.container.config.oauthRedirectURL.absoluteString)
            }
            .font(.footnote.monospaced())
        }
        .padding()
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled)
        }
    }
}

#Preview {
    if let container = try? Container.bootstrap() {
        ContentView().environmentObject(BootstrapEnv(container: container))
    }
}

