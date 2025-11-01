//
//  HomeView.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingManualEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.functional")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Pull Up Mastery")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top)
                    
                    // Recent workout summary
                    if let lastWorkout = workouts.first {
                        SimpleStatsCard(workouts: workouts)
                        WorkoutCard(workout: lastWorkout, isLastWorkout: true)
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
        .sheet(isPresented: $showingManualEntry) {
            ManualWorkoutEntryView()
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
