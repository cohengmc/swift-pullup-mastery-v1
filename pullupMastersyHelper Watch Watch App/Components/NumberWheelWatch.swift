//
//  NumberWheelWatch.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import SwiftUI

struct NumberWheelWatch: View {
    @Binding var selectedValue: Int
    let minValue: Int
    let maxValue: Int
    
    init(selectedValue: Binding<Int>, minValue: Int = 0, maxValue: Int = 20) {
        self._selectedValue = selectedValue
        self.minValue = minValue
        self.maxValue = maxValue
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(selectedValue)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Picker with wheel style - automatically uses Digital Crown when focused on watchOS
            Picker("Reps", selection: $selectedValue) {
                ForEach(minValue...maxValue, id: \.self) { number in
                    Text("\(number)")
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 80)
            .onChange(of: selectedValue) { oldValue, newValue in
                HapticManagerWatch.shared.selection()
            }
            
            Text("Reps")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @State var selectedValue = 10
    
    return NumberWheelWatch(selectedValue: $selectedValue, minValue: 0, maxValue: 30)
        .padding()
}

