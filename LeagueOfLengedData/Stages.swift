//
//  Stages.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 7/2/25.
//

import Foundation

/**
 * Stage 0 is the first step to collect league of legedns data. It collect puuid of certian tier.
 */
func stage0() async throws {
    let data = try await fetchLeagueListDTO()
    saveLeagueListDTO(data)
    savePuuid(data)
}

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

/** Get and save matchInfo and timeline
 */
func stage2() async throws {
    let matchIds = try loadMatchId()
    let maxInfo = 100;
    var failedMatchIds = [String]()
    var count = 0;
    for matchId in matchIds {
        
        // Get match info
        do {
            count += 1
            let matchInfo = try await fetchMatchInfo(matchId: matchId)
            try await Task.sleep(nanoseconds: 1400_000_000)
            
            let matchTimeline = try await fetchTimeline(matchId)
            try await Task.sleep(nanoseconds: 1400_000_000)
            
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

//
// Stage 3 - Analyze match info & timelines, aggregate into ChampionStats
//


/// Runs the "analysis" stage:
/// 1) Loads the list of match IDs you previously saved.
/// 2) Loads each match's `MatchDto` and `TimelineDto`.
/// 3) Aggregates per-champion stats from match info (itmes, runes, spells, wins).
/// 4) Reconstructs item build order from the timeline for each participant and
/// record boots + first/second/... core items into `ChampionStats`.
/// 5) Saves the aggregated `ChampionStats` dictionary to disk.
///
/// Assumptions:
/// - `loadMatchId( )` returns the same IDs you fetched in earlier stages.
/// - `loadMatchInfo(_:)` and `loadTimeline(_:)` are implemented and read from disk.
func stage3() async throws {
    let matchIds = try loadMatchId()
    var champions: [String : ChampionStats] = [:]
    
    
    for matchId in matchIds {
        // load
        let matchInfo = try loadMatchInfo(matchId)
        guard let timeline = try loadTimeline(matchId) else {
            continue
        }
        
        // this will map participant's number to champion name for each match
        // the reason why we need is because Riot api doens't provide champion
        // that corresonds to participant's number
        var participantsChampion: [String:String] = [:]     // [puuid : champion name]
        var participantIds: [String:Int] = [:]      // [puuid : participant number]
        
        
        // Aggregate champion stats from match info
        // This covers wins/losses, end-of-game item tallies, rune, spelss, etc.
        let participants: [ParticipantDto] = matchInfo.info.participants
        
        
        // Check if there is champion name in the dictionary
        // If isn't add new champoion and match info in the dictionary
        for participant in participants {
            
            participantsChampion[participant.puuid] = participant.championName
            
            if let existingChampion = champions[participant.championName] {
                existingChampion.addMatch(participant: participant)
                continue
            }
            let champion = ChampionStats(championName: participant.championName)
            champion.addMatch(participant: participant)
            champions[champion.championName] = champion
        }
        
        // TODO: item build
        for participant in timeline.info.participants {
            participantIds[participant.puuid] = participant.participantId
            
        }
    }
    
    try saveChampionStats(champions)
}
//
//func stage4() async throws {
//    let data = try await fetchTimeline("NA1_5313388433")
//    saveTimeline(data)
//}

