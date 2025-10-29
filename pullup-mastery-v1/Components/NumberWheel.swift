//
//  NumberWheel.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI

struct NumberWheel: View {
    @Binding var selectedValue: Int
    let minValue: Int
    let maxValue: Int
    
    init(selectedValue: Binding<Int>, minValue: Int = 0, maxValue: Int = 20) {
        self._selectedValue = selectedValue
        self.minValue = minValue
        self.maxValue = maxValue
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Reps")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Picker("Select Reps", selection: $selectedValue) {
                ForEach(minValue...maxValue, id: \.self) { number in
                    Text("\(number)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .clipped()
            .onChange(of: selectedValue) { oldValue, newValue in
                HapticManager.shared.selection()
            }
        }
        .frame(maxWidth: 120) // Constrain width for better proportions
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var selectedValue = 10
    
    return VStack {
        Text("Selected: \(selectedValue)")
            .font(.headline)
            .padding()
        
        NumberWheel(selectedValue: $selectedValue, minValue: 0, maxValue: 30)
            .padding()
        
        Spacer()
    }
}
