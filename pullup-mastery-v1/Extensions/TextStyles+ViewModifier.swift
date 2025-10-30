//
//  TextStyles+ViewModifier.swift
//  pullup-mastery-v1
//
//  Created by Assistant on 10/29/25.
//

import SwiftUI
import Foundation

struct LargeSecondaryTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 64, weight: .medium))
            .foregroundColor(.secondary)
    }
}

struct LargePrimaryTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 100, weight: .thin))
            .foregroundColor(.blue)
    }
}


struct LargePrimaryButtonTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(.blue)
            .clipShape(Capsule())
    }
}

extension Date {
    
    /// Formats the date as "MMM d'st/nd/th', yyyy"
    /// (e.g., "Oct 30th, 2025")
    func formattedWithOrdinalDay() -> String {
        
        // 1. Get the day component as an integer
        let day = Calendar.current.component(.day, from: self)
        
        // 2. Get the month and year parts as strings
        let formatter = DateFormatter()
        
        formatter.dateFormat = "MMM"
        let month = formatter.string(from: self)
        
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: self)
        
        // 3. Determine the correct suffix
        let suffix: String
        switch day {
        case 11, 12, 13:
            suffix = "th"
        default:
            switch (day % 10) { // Get the last digit
            case 1:  suffix = "st"
            case 2:  suffix = "nd"
            case 3:  suffix = "rd"
            default: suffix = "th"
            }
        }
        
        // 4. Combine all the parts
        return "\(month) \(day)\(suffix), \(year)"
    }
}

extension View {
    func largeSecondaryTextStyle() -> some View {
        modifier(LargeSecondaryTextStyle())
    }
    
    func largePrimaryTextStyle() -> some View {
        modifier(LargePrimaryTextStyle())
    }
    
    func largePrimaryButtonTextStyle() -> some View {
        modifier(LargePrimaryButtonTextStyle())
    }
}


