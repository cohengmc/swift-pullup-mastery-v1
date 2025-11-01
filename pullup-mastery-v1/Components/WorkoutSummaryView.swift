//
//  WorkoutSummaryView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData
import UIKit

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
                        
                        Button(action: shareWorkoutResults) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                                .padding()
                                .background(.blue)
                                .clipShape(Circle())
                        }
                        
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
        // Create the chart view
        let chartView = RepBreakdownChart(
            title: workout.type.rawValue,
            data: workout.sets,
            totalReps: workout.totalReps,
            date: workout.date
        )
        
        // Render the chart to an image
        if let image = renderChartToImage(chartView) {
            // Present the share sheet
            presentShareSheet(with: image)
        }
    }
    
    private func renderChartToImage(_ view: RepBreakdownChart) -> UIImage? {
        let hostingController = UIHostingController(rootView: view)
        
        // Set a reasonable size for the image (adjust as needed)
        let targetSize = CGSize(width: 800, height: 600)
        hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
        hostingController.view.backgroundColor = .systemBackground
        
        // Ensure proper layout
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // Render to image using snapshot - drawHierarchy captures SwiftUI views properly
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
        
        return image
    }
    
    private func presentShareSheet(with image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // Find the topmost view controller
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        // Create and present the activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // Configure for iPad (popover)
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = topViewController.view
            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX,
                                       y: topViewController.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topViewController.present(activityViewController, animated: true)
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
