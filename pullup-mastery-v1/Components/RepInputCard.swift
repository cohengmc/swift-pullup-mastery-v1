//
//  RepInputCard.swift
//  pullup-mastery-v1
//
//  Created by Assistant on 11/1/25.
//

import SwiftUI

struct RepInputCard: View {
    @Binding var repValues: [Int]
    let workoutType: WorkoutType
    let enableAutoPopulate: Bool
    
    init(repValues: Binding<[Int]>, workoutType: WorkoutType, enableAutoPopulate: Bool = true) {
        self._repValues = repValues
        self.workoutType = workoutType
        self.enableAutoPopulate = enableAutoPopulate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reps per Set")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(0..<workoutType.maxSets, id: \.self) { index in
                RepInputRow(
                    setNumber: index + 1,
                    value: Binding(
                        get: { index < repValues.count ? repValues[index] : 0 },
                        set: { newValue in
                            updateRepValue(at: index, to: newValue)
                        }
                    ),
                    maxValue: index == 0 ? 20 : (index > 0 && index <= repValues.count ? repValues[index - 1] : 20)
                )
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func updateRepValue(at index: Int, to newValue: Int) {
        // Ensure array is large enough
        while repValues.count <= index {
            repValues.append(0)
        }
        
        // Apply constraint: cannot exceed previous set's value
        let maxAllowed = index == 0 ? 20 : repValues[index - 1]
        let constrainedValue = max(0, min(20, min(newValue, maxAllowed)))
        
        repValues[index] = constrainedValue
        
        // Auto-populate subsequent sets with the new value (constrained by previous set)
        // Only do this if auto-populate is enabled
        if enableAutoPopulate && constrainedValue > 0 {
            for i in (index + 1)..<repValues.count {
                // Each subsequent set gets the value of the set we just changed,
                // but constrained by the previous set's value
                let previousSetValue = i > 0 ? repValues[i - 1] : 20
                repValues[i] = min(constrainedValue, previousSetValue)
            }
        }
    }
}

struct RepInputRow: View {
    let setNumber: Int
    @Binding var value: Int
    let maxValue: Int
    
    @State private var textValue: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)
            
            // Text Field
            TextField("0", text: $textValue)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .focused($isTextFieldFocused)
                .onChange(of: textValue) { oldValue, newValue in
                    // Only allow numeric input
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        textValue = filtered
                    }
                    
                    if let intValue = Int(filtered) {
                        let clamped = max(0, min(maxValue, intValue))
                        if clamped != value {
                            value = clamped
                            if clamped != intValue {
                                textValue = "\(clamped)"
                            }
                        }
                    } else if filtered.isEmpty {
                        value = 0
                    }
                }
                .onChange(of: value) { oldValue, newValue in
                    // Update text field when value changes from outside (e.g., auto-population)
                    // Only update if not currently being edited by user
                    if oldValue != newValue && !isTextFieldFocused {
                        textValue = newValue > 0 ? "\(newValue)" : ""
                    }
                }
            
            // Stepper
            HStack(spacing: 8) {
                Button(action: {
                    if value > 0 {
                        value = max(0, value - 1)
                        HapticManager.shared.selection()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value > 0 ? .blue : .gray)
                }
                .disabled(value == 0)
                
                Button(action: {
                    if value < maxValue {
                        value = min(maxValue, value + 1)
                        HapticManager.shared.selection()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value < maxValue ? .blue : .gray)
                }
                .disabled(value >= maxValue)
            }
            
            Spacer()
            
            // Max indicator
            if setNumber > 1 {
                Text("max: \(maxValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .onAppear {
            textValue = value > 0 ? "\(value)" : ""
        }
    }
}

#Preview {
    @Previewable @State var repValues = [0, 0, 0]
    
    return VStack {
        RepInputCard(repValues: $repValues, workoutType: .maxDay)
    }
    .padding()
}

