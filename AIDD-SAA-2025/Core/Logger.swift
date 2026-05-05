import Foundation
import os

enum Log {
    static let auth          = Logger(subsystem: subsystem, category: "auth")
    static let app           = Logger(subsystem: subsystem, category: "app")
    static let dataSupabase  = Logger(subsystem: subsystem, category: "data.supabase")
    static let presentation  = Logger(subsystem: subsystem, category: "presentation")
    static let home          = Logger(subsystem: subsystem, category: "home")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sun-asterisk.aidd-saa-2025"
}
