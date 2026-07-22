import SwiftUI

struct RootView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var entitlements: EntitlementsStore
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            TankListView(showSettings: $showSettings)
                .background(Theme.charcoal.ignoresSafeArea())
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
        .tint(Theme.rustBright)
    }
}
