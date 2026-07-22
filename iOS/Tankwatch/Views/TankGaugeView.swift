import SwiftUI

/// The signature animated hook: a vertical tank-level gauge that fills/drains
/// like a fuel gauge, with a satisfying spring-driven fill animation whenever
/// the displayed percent changes (e.g. right after logging a new reading).
struct TankGaugeView: View {
    let percentFull: Double?
    var width: CGFloat = 64
    var height: CGFloat = 160

    @State private var animatedPercent: Double = 0

    private var status: TankStatus {
        TankStatus.status(forLatestPercent: percentFull)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Outer tank shell.
            RoundedRectangle(cornerRadius: width * 0.28)
                .fill(Theme.charcoalElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.28)
                        .stroke(Theme.cream.opacity(0.15), lineWidth: 2)
                )

            // Fill level.
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: max(width * 0.28 - 4, 4))
                    .fill(
                        LinearGradient(
                            colors: [Theme.color(for: status).opacity(0.85), Theme.color(for: status)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: proxy.size.height * CGFloat(animatedPercent / 100))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(4)
            }

            // Tick marks at 20 / 60 thresholds for visual reference.
            GeometryReader { proxy in
                ForEach([20.0, 60.0], id: \.self) { mark in
                    Rectangle()
                        .fill(Theme.charcoal.opacity(0.6))
                        .frame(height: 1.5)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * (1 - mark / 100))
                }
            }

            VStack {
                Spacer()
                if let percentFull {
                    Text("\(Int(percentFull.rounded()))%")
                        .font(Theme.captionFont())
                        .foregroundStyle(Theme.cream)
                        .padding(.bottom, 8)
                } else {
                    Text("—")
                        .font(Theme.captionFont())
                        .foregroundStyle(Theme.creamDim)
                        .padding(.bottom, 8)
                }
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            animate(to: percentFull ?? 0)
        }
        .onChange(of: percentFull) { _, newValue in
            animate(to: newValue ?? 0)
        }
    }

    private func animate(to target: Double) {
        withAnimation(.spring(response: 0.9, dampingFraction: 0.72, blendDuration: 0.2)) {
            animatedPercent = target
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        TankGaugeView(percentFull: 85)
        TankGaugeView(percentFull: 45)
        TankGaugeView(percentFull: 8)
        TankGaugeView(percentFull: nil)
    }
    .padding()
    .background(Theme.charcoal)
}
