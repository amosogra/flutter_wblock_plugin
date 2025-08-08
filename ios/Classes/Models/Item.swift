//
//  Item.swift
//  wBlock
//
//  Created by Alexander Skula on 5/23/25.
//

import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftData)
@available(macOS 14.0, iOS 17.0, *)
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
#else
// Fallback implementation for older systems
class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
#endif