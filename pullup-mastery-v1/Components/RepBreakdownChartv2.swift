//
//  RepBreakdownChart.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/30/25.
//

import SwiftUI

/// Bar chart view that displays performance data with title, total reps, and visual bars.
/// This is a SwiftUI translation of the React component.
struct RepBreakdownChart: View {
    // MARK: - Properties (from React Props)

    let title: String
    let data: [Int]
    let totalReps: Int
    let date: Date
    
    // MARK: - Computed Properties (from React useMemo)

    /// Finds the maximum value in the data, defaulting to 1 to avoid division by zero
    private var maxValue: Int {
        max(data.max() ?? 0, 1)
    }

    // MARK: - View Body

    var body: some View {
        let formattedString = date.formattedWithOrdinalDay()

        // Main container (VStack replaces flex-direction: column)
        VStack(alignment: .center, spacing: 10) {
            
            // Context
            HStack(){
                Text("Pull Up Mastery")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(formattedString)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            // Title and Total Reps Row (HStack replaces flex-direction: row)
            HStack(alignment: .center) {
                
                // Left Column (Title and Breakdown)
                VStack(alignment: .leading) {
                    // Title
                    Text(title)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
//                        .lineLimit(1) // Prevents wrapping
                    
                    Spacer()

                    
                    // Rep Breakdown Label
                    Text("Rep Breakdown")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                    
                    
                }
                .frame(maxHeight: .infinity) // <-- 2. KEEP this to fill the parent
                
                // Spacer replaces justify-content: space-between
                Spacer()
                
                // Total Reps Circle Section (This section is correct)
                VStack(alignment: .center) {
                    // ZStack layers the text on top of the circle
                    ZStack {
                        Text("\(totalReps)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 72, height: 72)
                    .background(.green)
                    .clipShape(Circle()) // Replaces borderRadius: "50%"
                                        
                    Text("Total Reps")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .fixedSize(horizontal: false, vertical: true) // <-- 3. ADD THIS to the HStack
            

            // Bar Chart Section
            HStack(alignment: .bottom, spacing: 8) {
                // ForEach replaces data.map
                ForEach(Array(data.enumerated()), id: \.offset) {
                    index, value in

                    // Bar Column (VStack replaces flex-direction: column)
                    VStack(spacing: 4) {
                        // Data Label on top
                        Text("\(value)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)

                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.blue)
                            .frame(height: barHeight(for: value))

                        // Sequential Label
                        Text("\(index + 1)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    // .frame replaces flex: 1 and minWidth
                    .frame(minWidth: 20, maxWidth: .infinity)
                }
            }
            .frame(height: 120)  // Fixed height for the chart container
            


        }
        .padding(20)
        .frame(minWidth: 280, minHeight: 200, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    /// Calculates the dynamic height of a bar based on its value
    private func barHeight(for value: Int) -> CGFloat {
        // (value / maxValue) * 80, with a minHeight of 4
        let height = (CGFloat(value) / CGFloat(maxValue)) * 80
        return max(height, 4)
    }
}

// MARK: - Preview

// The PreviewProvider replaces the Framer "addPropertyControls"
// and provides a live preview in Xcode.
struct RepBreakdownChart_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Add a dark background to the preview canvas for contrast
            Color.black.ignoresSafeArea()

            RepBreakdownChart(
                title: "Max Day",
                data: [6, 6, 6, 6, 6, 5, 5, 5, 5, 5],
                totalReps: 55,
                date: Date()
    
            )
            .padding()
            
        }
    }
}
