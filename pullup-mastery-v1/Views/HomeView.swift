//
//  HomeView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingManualEntry = false
    @State private var selectedWorkout: Workout?
    @State private var navigationResetId = UUID()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack(spacing: 8) {
                        Image("PullUpIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                        
                        Text("Pull Up Mastery")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top)
                    
                    // Recent workout summary
                    if let lastWorkout = workouts.first {
                        SimpleStatsCard(workouts: workouts)
                        WorkoutCard(workout: lastWorkout, isLastWorkout: true)
                            .onTapGesture {
                                selectedWorkout = lastWorkout
                            }
                    }
                    
                    // Workout type selection
                    VStack(alignment: .leading, spacing: 16) {
                        
                        HStack(){
                            Text("Start Workout")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            Button(action: {
                                showingManualEntry = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    
                            }
                            .padding(.horizontal)
                            .padding(.trailing, 16)
                        }
                        
                        
                        LazyVStack(spacing: 12) {
                            ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                                WorkoutTypeCard(workoutType: workoutType)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Program info
                    ProgramInfoCard()
                        .padding(.horizontal)
                }
            }
        }
        .id(navigationResetId) // Reset NavigationView when needed
        .sheet(isPresented: $showingManualEntry) {
            ManualWorkoutEntryView()
        }
        .sheet(item: $selectedWorkout) { workout in
            NavigationView {
                WorkoutSummaryView(workout: workout, showDeleteButton: true) {
                    selectedWorkout = nil
                }
            }
        }
        .onAppear {
            print("📱 [Phone] HomeView appeared, refreshing workouts...")
            // Refresh ModelContext to pick up changes from watch app
            refreshWorkouts()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("📱 [Phone] App entered foreground, refreshing workouts...")
            // Refresh when app comes to foreground
            refreshWorkouts()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutCompleted"))) { _ in
            print("📱 [Phone] Received WorkoutCompleted notification")
            // Reset navigation state after user dismisses workout summary
            // Small delay to ensure WorkoutView is fully dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                navigationResetId = UUID()
                refreshWorkouts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WatchWorkoutCompleted"))) { _ in
            print("📱 [Phone] Received WatchWorkoutCompleted notification, refreshing workouts...")
            // Refresh when workout completed on watch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                navigationResetId = UUID()
                refreshWorkouts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutDataReceived"))) { notification in
            print("📱 [Phone] Received WorkoutDataReceived notification")
            if let workout = notification.userInfo?["workout"] as? Workout {
                print("📱 [Phone] Saving workout to database: \(workout.id)")
                modelContext.insert(workout)
                do {
                    try modelContext.save()
                    print("✅ [Phone] Workout saved successfully")
                    // Refresh workouts to show the new one
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigationResetId = UUID()
                        refreshWorkouts()
                    }
                } catch {
                    print("❌ [Phone] Error saving workout: \(error)")
                }
            }
        }
    }
    
    private func refreshWorkouts() {
        print("🔄 [Phone] refreshWorkouts() called")
        
        // Get count before refresh
        let descriptorBefore = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let countBefore = (try? modelContext.fetch(descriptorBefore).count) ?? 0
        print("📊 [Phone] Workout count before refresh: \(countBefore)")
        
        // Force ModelContext to refresh by processing pending changes
        modelContext.processPendingChanges()
        print("🔄 [Phone] Processed pending changes")
        
        // Refetch workouts to ensure we have latest data
        let descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        do {
            let fetchedWorkouts = try modelContext.fetch(descriptor)
            print("✅ [Phone] Fetched \(fetchedWorkouts.count) workouts")
            print("📊 [Phone] Workout count after refresh: \(fetchedWorkouts.count)")
            
            if fetchedWorkouts.count != countBefore {
                print("🔄 [Phone] Workout count changed: \(countBefore) -> \(fetchedWorkouts.count)")
            }
            
            if let latestWorkout = fetchedWorkouts.first {
                print("✅ [Phone] Latest workout: \(latestWorkout.type.rawValue) on \(latestWorkout.date)")
                print("✅ [Phone] Latest workout ID: \(latestWorkout.id)")
            } else {
                print("ℹ️ [Phone] No workouts found in database")
            }
        } catch {
            print("❌ [Phone] Error refreshing workouts: \(error)")
            if let nsError = error as NSError? {
                print("❌ [Phone] Error domain: \(nsError.domain), code: \(nsError.code)")
            }
        }
    }
}

struct WorkoutTypeCard: View {
    let workoutType: WorkoutType
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationLink(destination: WorkoutView(workoutType: workoutType)) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(workoutType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.trailing, 8)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch workoutType {
        case .maxDay: return "flame.fill"
        case .subMaxVolume: return "speedometer"
        case .ladderVolume: return "arrow.up.right"
        }
    }
    
    private var iconColor: Color {
        switch workoutType {
        case .maxDay: return .maxDayColor
        case .subMaxVolume: return .subMaxColor
        case .ladderVolume: return .ladderColor
        }
    }
}

struct ProgramInfoCard: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Program Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .padding(.trailing, 8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Build strength with the proven 3-day program")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Prerequisites: 5-12 Pull Ups")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Duration: 6-12+ Weeks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Schedule: 3 non-consecutive days per week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Workout.self], inMemory: true)
}
