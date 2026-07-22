import SwiftUI

struct TankDetailView: View {
    let tank: Tank

    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var entitlements: EntitlementsStore

    @State private var showLogReading = false
    @State private var showPaywall = false

    private var latest: Reading? {
        dataStore.latestReading(for: tank.id)
    }

    private var status: TankStatus {
        TankStatus.status(forLatestPercent: latest?.percentFull)
    }

    private var history: [Reading] {
        dataStore.readings(for: tank.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TankGaugeView(percentFull: latest?.percentFull, width: 100, height: 220)
                    .padding(.top, 20)

                Text(status.displayName)
                    .font(Theme.headlineFont())
                    .foregroundStyle(Theme.color(for: status))

                Button {
                    attemptLog()
                } label: {
                    Text("Log a Reading")
                        .font(Theme.bodyFont().weight(.semibold))
                        .foregroundStyle(Theme.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: Theme.smallCornerRadius).fill(Theme.brass))
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(Theme.headlineFont())
                        .foregroundStyle(Theme.cream)
                        .padding(.horizontal)

                    if history.isEmpty {
                        Text("No readings logged yet.")
                            .font(Theme.bodyFont())
                            .foregroundStyle(Theme.creamDim)
                            .padding(.horizontal)
                    } else {
                        ForEach(history) { reading in
                            HStack {
                                Text(reading.date, style: .date)
                                    .font(Theme.bodyFont())
                                    .foregroundStyle(Theme.creamDim)
                                Spacer()
                                Text("\(Int(reading.percentFull.rounded()))%")
                                    .font(Theme.bodyFont().weight(.semibold))
                                    .foregroundStyle(Theme.color(for: TankStatus.status(forLatestPercent: reading.percentFull)))
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: Theme.smallCornerRadius).fill(Theme.charcoalCard))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 32)
        }
        .background(Theme.charcoal.ignoresSafeArea())
        .navigationTitle(tank.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogReading) {
            LogReadingView(tank: tank)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func attemptLog() {
        let allowed = RateLimiter.canLogReading(
            isPro: entitlements.isPro,
            existingLogs: dataStore.allReadingDates,
            now: Date()
        )
        if allowed {
            showLogReading = true
        } else {
            showPaywall = true
            Task {
                await UpgradeNudgeScheduler().handleLimitHit(now: Date())
            }
        }
    }
}
