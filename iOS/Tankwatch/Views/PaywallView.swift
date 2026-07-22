import SwiftUI

/// Hard-block modal shown when a free user attempts to log beyond the
/// monthly limit.
struct PaywallView: View {
    @EnvironmentObject var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.rustBright)

            Text("You've used all 5 free logs this month")
                .font(Theme.titleFont())
                .foregroundStyle(Theme.cream)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Tankwatch Pro unlocks unlimited level-check logging every month, so you never lose track of a tank again.")
                .font(Theme.bodyFont())
                .foregroundStyle(Theme.creamDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let product = entitlements.products.first {
                Text("\(product.displayPrice) / month")
                    .font(Theme.headlineFont())
                    .foregroundStyle(Theme.brass)
            }

            Spacer()

            Button {
                Task {
                    await entitlements.purchasePro()
                    if entitlements.isPro { dismiss() }
                }
            } label: {
                Text("Upgrade to Pro")
                    .font(Theme.bodyFont().weight(.semibold))
                    .foregroundStyle(Theme.charcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: Theme.smallCornerRadius).fill(Theme.brass))
            }
            .padding(.horizontal)

            Button("Maybe Later") {
                dismiss()
            }
            .font(Theme.bodyFont())
            .foregroundStyle(Theme.creamDim)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.charcoal.ignoresSafeArea())
        .interactiveDismissDisabled(false)
    }
}
