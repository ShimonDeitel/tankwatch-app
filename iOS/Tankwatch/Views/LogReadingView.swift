import SwiftUI

struct LogReadingView: View {
    let tank: Tank

    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var percent: Double = 50
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                TankGaugeView(percentFull: percent, width: 80, height: 180)
                    .padding(.top, 12)

                VStack(spacing: 8) {
                    Text("\(Int(percent.rounded()))% full")
                        .font(Theme.gaugeNumberFont())
                        .foregroundStyle(Theme.cream)
                    Slider(value: $percent, in: 0...100, step: 1)
                        .tint(Theme.rustBright)
                        .padding(.horizontal)
                }

                TextField("Note (optional)", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Spacer()

                Button {
                    dataStore.addReading(tankID: tank.id, percentFull: percent, note: note.isEmpty ? nil : note)
                    dismiss()
                } label: {
                    Text("Save Reading")
                        .font(Theme.bodyFont().weight(.semibold))
                        .foregroundStyle(Theme.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: Theme.smallCornerRadius).fill(Theme.brass))
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .background(Theme.charcoal.ignoresSafeArea())
            .dismissKeyboardOnTap()
            .navigationTitle("Log Reading — \(tank.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
