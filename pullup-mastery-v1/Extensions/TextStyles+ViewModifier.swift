//
//  TextStyles+ViewModifier.swift
//  pullup-mastery-v1
//
//  Created by Assistant on 10/29/25.
//

import SwiftUI

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


