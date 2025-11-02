//
//  WorkoutSummaryView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    let workout: Workout
    let onDismiss: () -> Void
    let showDeleteButton: Bool
    
    init(workout: Workout, showDeleteButton: Bool = false, onDismiss: @escaping () -> Void) {
        self.workout = workout
        self.showDeleteButton = showDeleteButton
        self.onDismiss = onDismiss
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var isShowingShareSheet = false
    @State private var itemToShare: ImageShareItem?
    
    // Chart view for rendering
    private var chartView: RepBreakdownChart {
        RepBreakdownChart(
            title: workout.type.rawValue,
            data: workout.sets,
            totalReps: workout.totalReps,
            date: workout.date
        )
    }
    
    var body: some View {
            VStack(alignment: .center, spacing: 4) {
                // Delete button
                if showDeleteButton {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.15))
                                .clipShape(Circle())
                        }
//                        .padding(.trailing)
                    }
                }
                
                VStack(alignment: .center, spacing: 24) {

                
                RepBreakdownChart(
                    title: workout.type.rawValue,
                    data: workout.sets,
                    totalReps: workout.totalReps,
                    date: workout.date
                )
            
                
                // Actions
                    HStack(spacing: 8) {
                        
#if DEBUG
                        if FeatureFlags.hideFeature {
                            
                            Button(action: shareWorkoutResults) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.blue)
                                    .clipShape(Circle())
                            }
                        }
                        #endif
                        
                        Button(action: {
                            // Dismiss this view first (pops back to WorkoutView)
                            dismiss()
                            // Then call onDismiss to dismiss WorkoutView and return to HomeView
                            // Use async to ensure the first dismiss completes before the second
                            DispatchQueue.main.async {
                                onDismiss()
                            }
                        }) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.blue)
                                .clipShape(Capsule())
                        }
                        
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .padding()
                                .background(.blue)
                                .clipShape(Circle())
                        }
                    }
                    
                    
                    
                }
        
                
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingEditSheet) {
                EditWorkoutView(workout: workout)
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let itemToShare = itemToShare {
                    ShareSheet(activityItems: [itemToShare])
                } else {
                    // Fallback - should not happen, but handles edge case
                    EmptyView()
                }
            }
            .alert("Delete Workout", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteWorkout()
                }
            } message: {
                Text("Are you sure you want to delete this workout? This action cannot be undone.")
            }
    }
    
    private func deleteWorkout() {
        modelContext.delete(workout)
        do {
            try modelContext.save()
            // Dismiss the sheet
            dismiss()
            DispatchQueue.main.async {
                onDismiss()
            }
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
    
    private func shareWorkoutResults() {
        // Render the chart as an image with appropriate size
        // Chart has minWidth: 280, minHeight: 200, so use a size that accommodates content
        let chartSize = CGSize(width: 400, height: 500)
        if let image = renderViewAsImage(view: chartView, size: chartSize) {
            // Create the share item with a descriptive title
            let title = "\(workout.type.rawValue) - \(workout.date.formatted(date: .abbreviated, time: .omitted))"
            self.itemToShare = ImageShareItem(image: image, title: title)
            self.isShowingShareSheet = true
        }
    }
}

struct EditWorkoutView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var repValues: [Int] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    RepInputCard(repValues: $repValues, workoutType: workout.type, enableAutoPopulate: false)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Edit Workout Details")
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
                }
            }
        }
        .onAppear {
            // Initialize repValues with current workout sets
            repValues = workout.sets
        }
    }
    
    private func saveWorkout() {
        // Update the workout's sets with the new values
        workout.sets = repValues
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
        }
    }
}


// MARK: - Preview Helpers
private enum WorkoutSummaryPreviewData {
    static var sampleWorkout: Workout = {
        let w = Workout(type: .ladderVolume)
        w.sets = [6, 5, 4,4,4]
        return w
    }()
}

#Preview {
    WorkoutSummaryView(workout: WorkoutSummaryPreviewData.sampleWorkout) {
        print("Dismissed")
    }
    .modelContainer(for: [Workout.self], inMemory: true)
}
