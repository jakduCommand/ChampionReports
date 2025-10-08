//
//  Stage1.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/25/25.
//

import Foundation

/**
 * Stage 1 uses puuid that are collected from stag 0. It collects matchID and filters out
 * duplicated matchID
 */
func stage1() async throws {
    let puuids = try loadPuuids()
    var allMatchIDs = Set<String>()
    var failedPuuids = [String]() // for logging
    for puuid in puuids {
        do {
            let matchIDs = try await fetchMatchIDs(for: puuid)
            allMatchIDs.formUnion(matchIDs)
        } catch {
            print("Failed to fetch matches for puuid: \(puuid)\nReason: \(error)")
            failedPuuids.append(puuid)
            continue
        }
        
        // delay
        try await Task.sleep(nanoseconds: 1400_000_000)
        
        // break condition
        if allMatchIDs.count > 10000 {
            print("Stopping: collected \(allMatchIDs.count) match IDs.")
            break
        }
    }
    
    saveMatchIDs(Array(allMatchIDs))
}
