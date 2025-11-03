//
//  FeatureFlags.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/28/25.
//

import Foundation

/// Feature flags for runtime control of app features
/// These can be toggled without recompiling the app
struct FeatureFlags {
    /// Enable "Skip Rest" buttons for testing/debugging
    /// Set to `true` when ready to enable, `false` to disable
    static let hideFeature: Bool = false
}

