import SwiftUI

struct FilterMenu: View {
    @Binding var selectedTypes: Set<Int>
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Medientyp")
                .font(.headline)
            ForEach([0, 1, 2], id: \.self) { type in
                Button(action: {
                    if selectedTypes.contains(type) {
                        selectedTypes.remove(type)
                    } else {
                        selectedTypes.insert(type)
                    }
                }) {
                    HStack {
                        Text(label(for: type))
                        Spacer()
                        if selectedTypes.contains(type) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Text("Datum")
                .font(.headline)
            DatePicker("Von", selection: $startDate, displayedComponents: .date)
            DatePicker("Bis", selection: $endDate, displayedComponents: .date)
        }
        .padding()
    }
    
    private func label(for type: Int) -> String {
        switch type {
        case 0: return "Bilder"
        case 1: return "LivePhotos"
        case 2: return "Videos"
        default: return "Unbekannt"
        }
    }
}