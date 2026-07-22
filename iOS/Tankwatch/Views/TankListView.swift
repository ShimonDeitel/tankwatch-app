import SwiftUI

struct TankListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var entitlements: EntitlementsStore
    @Binding var showSettings: Bool

    @State private var showAddTank = false
    @State private var showSoftNudge = false
    @State private var didShowSoftNudgeThisSession = false

    private var suggestedTank: Tank? {
        dataStore.suggestedRefillTank()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let suggestedTank {
                    SuggestionBanner(tank: suggestedTank, dataStore: dataStore)
                }

                if showSoftNudge {
                    SoftNudgeBanner(onUpgradeTapped: {
                        showSoftNudge = false
                        NotificationCenter.default.post(name: .tankwatchShowPaywall, object: nil)
                    }, onDismiss: {
                        showSoftNudge = false
                    })
                }

                if dataStore.tanks.isEmpty {
                    EmptyStateView(onAddTank: { showAddTank = true })
                        .padding(.top, 60)
                } else {
                    ForEach(dataStore.tanks.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })) { tank in
                        NavigationLink(value: tank) {
                            TankRow(tank: tank)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .navigationDestination(for: Tank.self) { tank in
            TankDetailView(tank: tank)
        }
        .navigationTitle("Tankwatch")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Theme.cream)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddTank = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.rustBright)
                }
            }
        }
        .sheet(isPresented: $showAddTank) {
            AddTankView()
        }
        .onAppear {
            evaluateSoftNudge()
        }
    }

    private func evaluateSoftNudge() {
        guard !didShowSoftNudgeThisSession, !entitlements.isPro else { return }
        let remaining = RateLimiter.remainingLogsThisMonth(existingLogs: dataStore.allReadingDates, now: Date())
        if remaining == 1 {
            showSoftNudge = true
            didShowSoftNudgeThisSession = true
        }
    }
}

private struct SuggestionBanner: View {
    let tank: Tank
    let dataStore: DataStore

    private var percent: Double {
        dataStore.latestReading(for: tank.id)?.percentFull ?? 0
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.rustBright)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text("Refill this one first")
                    .font(Theme.captionFont())
                    .foregroundStyle(Theme.creamDim)
                Text("\(tank.name) — \(Int(percent.rounded()))%")
                    .font(Theme.headlineFont())
                    .foregroundStyle(Theme.cream)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.rust.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.rustBright.opacity(0.4), lineWidth: 1)
        )
    }
}

private struct EmptyStateView: View {
    let onAddTank: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.rustBright)
            Text("No tanks yet")
                .font(Theme.headlineFont())
                .foregroundStyle(Theme.cream)
            Text("Add your first propane tank, gas can, or oil tank to start tracking levels.")
                .font(Theme.bodyFont())
                .foregroundStyle(Theme.creamDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: onAddTank) {
                Text("Add a Tank")
                    .font(Theme.bodyFont().weight(.semibold))
                    .foregroundStyle(Theme.charcoal)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Theme.brass))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TankRow: View {
    let tank: Tank
    @EnvironmentObject var dataStore: DataStore

    private var latest: Reading? {
        dataStore.latestReading(for: tank.id)
    }

    private var status: TankStatus {
        TankStatus.status(forLatestPercent: latest?.percentFull)
    }

    var body: some View {
        HStack(spacing: 16) {
            TankGaugeView(percentFull: latest?.percentFull, width: 40, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(tank.name)
                    .font(Theme.headlineFont())
                    .foregroundStyle(Theme.cream)
                Text("\(tank.capacityAmount.formattedTrimmed) \(tank.capacityUnit.shortLabel) capacity")
                    .font(Theme.captionFont())
                    .foregroundStyle(Theme.creamDim)
                Text(status.displayName)
                    .font(Theme.captionFont().weight(.bold))
                    .foregroundStyle(Theme.color(for: status))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.creamDim)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.cornerRadius).fill(Theme.charcoalCard))
    }
}

extension Double {
    var formattedTrimmed: String {
        self.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}

extension Notification.Name {
    static let tankwatchShowPaywall = Notification.Name("tankwatchShowPaywall")
}
