//
//  HapticManagerWatch.swift
//  pullupMastersyHelper Watch Watch App
//
//  Created by Geoffrey Cohen on 12/19/25.
//

import Foundation
import WatchKit

// Haptic feedback helper for watchOS
struct HapticManagerWatch {
    static let shared = HapticManagerWatch()
    
    private init() {}
    
    func light() {
        WKInterfaceDevice.current().play(.click)
    }
    
    func medium() {
        WKInterfaceDevice.current().play(.click)
    }
    
    func heavy() {
        WKInterfaceDevice.current().play(.notification)
    }
    
    func selection() {
        WKInterfaceDevice.current().play(.click)
    }
    
    func success() {
        WKInterfaceDevice.current().play(.success)
    }
    
    func warning() {
        WKInterfaceDevice.current().play(.notification)
    }
    
    func error() {
        WKInterfaceDevice.current().play(.failure)
    }
}

