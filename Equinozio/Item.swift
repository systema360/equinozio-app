//
//  Item.swift
//  Equinozio
//
//  Created by Giuseppe Liscio on 03/06/2026.
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
