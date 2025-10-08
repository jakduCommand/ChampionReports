//
//  Lane.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/23/25.
//
import Foundation

struct LaneTable {
    // Lane: Champion Name
    var lose: [String:String]
    var win: [String:String]
    
    init() {
        self.lose = [
            "TOP": "unknown",
            "JUNGLE": "unknown",
            "MID": "unknown",
            "ADC": "unknown",
            "SUP": "unknown"
        ]
        
        self.win = [
            "TOP": "unknown",
            "JUNGLE": "unknown",
            "MID": "unknown",
            "ADC": "unknown",
            "SUP": "unknown"
        ]
    }
}
