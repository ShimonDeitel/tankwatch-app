import SwiftUI

struct AddTankView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var unit: CapacityUnit = .lbs
    @State private var capacityText: String = ""

    private var capacityValue: Double? {
        Double(capacityText)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (capacityValue ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tank Details") {
                    TextField("Name (e.g. Grill Propane)", text: $name)
                    Picker("Unit", selection: $unit) {
                        ForEach(CapacityUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    TextField("Capacity amount", text: $capacityText)
                        .keyboardType(.decimalPad)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.charcoal.ignoresSafeArea())
            .dismissKeyboardOnTap()
            .navigationTitle("Add Tank")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dataStore.addTank(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            capacityUnit: unit,
                            capacityAmount: capacityValue ?? 0
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
