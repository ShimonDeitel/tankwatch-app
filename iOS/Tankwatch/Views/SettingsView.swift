import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(entitlements.isPro ? "Pro" : "Free")
                            .foregroundStyle(entitlements.isPro ? Theme.brass : Theme.creamDim)
                    }
                    Button {
                        Task {
                            isRestoring = true
                            await entitlements.restorePurchases()
                            isRestoring = false
                        }
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                            if isRestoring {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRestoring)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(Theme.creamDim)
                    }
                }

                // MARK: - Future: More Apps section
                // TODO: Add a "More Apps" section here once the app-factory
                // cross-promotion catalog is wired up, matching the pattern
                // used in sibling apps (a simple list of other shipped apps
                // with App Store links).
            }
            .scrollContentBackground(.hidden)
            .background(Theme.charcoal.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
