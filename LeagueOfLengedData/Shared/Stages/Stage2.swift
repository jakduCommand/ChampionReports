//
//  Stage2.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/25/25.
//

import Foundation

/** Get and save matchInfo and timeline
 */
func stage2() async throws {
    let matchIds = try loadMatchId()
    let maxInfo = 1;
    var failedMatchIds = [String]()
    var count = 0;
    for matchId in matchIds {
        
        // Get match info
        do {
            
            let matchInfo = try await fetchMatchInfo(matchId: matchId)
            try await Task.sleep(nanoseconds: 1400_000_000)
            
            let matchTimeline = try await fetchTimeline(matchId)
            try await Task.sleep(nanoseconds: 1400_000_000)
            
            if matchInfo.info.gameMode != "CLASSIC" {
                continue
            }
            
            count += 1
            saveMatchInfo(matchId, matchInfo)
            
            saveTimeline(matchId, matchTimeline)
            print("\(count*100/maxInfo)%")
        } catch {
            print("Failed to fetch match info and timeline for matchID: \(matchId)\nReason: \(error)")
            failedMatchIds.append(matchId)
            continue
        }
        
        // delay
        
        
        if count >= maxInfo {
            print("Stopping: collected \(count) match info.")
            break;
        }
    }
}
