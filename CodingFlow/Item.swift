//
//  Item.swift
//  CodingFlow
//
//  Created by Kan Shao on 2026/1/4.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
