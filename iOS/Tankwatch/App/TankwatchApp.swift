import SwiftUI

@main
struct TankwatchApp: App {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var entitlements = EntitlementsStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataStore)
                .environmentObject(entitlements)
                .preferredColorScheme(.dark)
        }
    }
}
