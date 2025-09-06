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
        guard let timeline = try loadTimeline(matchId) else { continue }
        
        // Map puuid -> champion Name
        var championByPuuid: [String:String] = [:]     // [puuid : champion name]
        for p in matchInfo.info.participants {
            championByPuuid[p.puuid] = p.championName
            
            //Aggregate champion stats from MatchDto
            if let bucket = champions[p.championName] {
                bucket.addMatch(participant: p)
            } else {
                let bucket = ChampionStats(championName: p.championName)
                bucket.addMatch(participant: p)
                champions[bucket.championName] = bucket
            }
        }
        
        // Map participantId -> champoin name
        var championByParticipantId: [Int:String] = [:]
        for tp in timeline.info.participants {
            if let champ = championByPuuid[tp.puuid] {
                championByParticipantId[tp.participantId] = champ
            }
        }
        
        // Build per-champoin ordered item sequence for this match
        var championItemBuild: [String:[Int]] = [:]
        
        // Flatten. sort by time, and pre-filter to events we care about
        let events = timeline.info.frames
            .flatMap(\.events)
            .sorted{ $0.timestamp < $1.timestamp }
            .filter { $0.type == "ITEM_PURCHASED" || $0.type == "ITEM_UNDO"}
        
        for e in events {
            guard let pid = e.participantId,
                  let champ = championByParticipantId[pid] else { continue }
            
            switch e.type {
            case "ITEM_PURCHASED":
                if let id = e.itemId {
                    championItemBuild[champ, default: []].append(id)
                }
                
            case "ITEM_UNDO":
                if var seq = championItemBuild[champ], !seq.isEmpty {
                    seq.removeLast()
                    championItemBuild[champ] = seq
                }
                
            default:
                break
            }
        }
    }
    
    try saveChampionStats(champions)
}


//
//func stage4() async throws {
//    let data = try await fetchTimeline("NA1_5313388433")
//    saveTimeline(data)
//}

