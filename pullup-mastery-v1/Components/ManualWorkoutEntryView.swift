//
//  ManualWorkoutEntryView.swift
//  pullup-mastery-v1
//
//  Created by Assistant on 11/1/25.
//

import SwiftUI
import SwiftData

struct ManualWorkoutEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate: Date = Date()
    @State private var selectedWorkoutType: WorkoutType? = nil
    @State private var repValues: [Int] = []
    
    private var maxDate: Date {
        Date()
    }
    
    private var canSave: Bool {
        guard let workoutType = selectedWorkoutType else { return false }
        guard repValues.count == workoutType.maxSets else { return false }
        return repValues.allSatisfy { $0 > 0 && $0 <= 20 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    HStack(){
                        
                        // Date Picker
                        VStack(alignment: .center, spacing: 12) {
                            Text("Date")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .padding(.horizontal)
                            .padding(.trailing, 8)
                        }
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.trailing, 8)
                        
                        // Workout Type Picker
                        VStack(alignment: .center, spacing: 12) {
                            Text("Type")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Picker("Workout Type", selection: $selectedWorkoutType) {
                                Text("Select Type").tag(nil as WorkoutType?)
                                ForEach(WorkoutType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type as WorkoutType?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        
                    }
                    
                    
                    
                    
                    
                    // Rep Input Section
                    if let workoutType = selectedWorkoutType {
                        RepInputCard(repValues: $repValues, workoutType: workoutType)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Save Workout Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onChange(of: selectedWorkoutType) { oldValue, newValue in
            if let newType = newValue {
                // Initialize rep values array with zeros
                repValues = Array(repeating: 0, count: newType.maxSets)
            } else {
                repValues = []
            }
        }
    }
    
    private func saveWorkout() {
        guard let workoutType = selectedWorkoutType else { return }
        
        let workout = Workout(type: workoutType, date: selectedDate)
        workout.sets = repValues
        
        modelContext.insert(workout)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
            // Could show an alert here if needed
        }
    }
}

#Preview {
    ManualWorkoutEntryView()
        .modelContainer(for: [Workout.self], inMemory: true)
}
