import SwiftUI

/// Small dismissible banner shown once per session when a free user has
/// exactly 1 remaining log this month.
struct SoftNudgeBanner: View {
    let onUpgradeTapped: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "drop.triangle.fill")
                .foregroundStyle(Theme.amber)
            Text("1 free log left this month")
                .font(Theme.captionFont())
                .foregroundStyle(Theme.cream)
            Spacer()
            Button("Upgrade", action: onUpgradeTapped)
                .font(Theme.captionFont().weight(.bold))
                .foregroundStyle(Theme.rustBright)
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.creamDim)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Theme.smallCornerRadius).fill(Theme.charcoalElevated))
    }
}
