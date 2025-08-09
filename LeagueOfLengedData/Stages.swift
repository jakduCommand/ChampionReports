//
//  Stages.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 7/2/25.
//

import Foundation

func stage0() async throws {
    let data = try await fetchLeagueListDTO()
    saveLeagueListDTO(data)
    savePuuid(data)
}

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

func stage2() async throws {
    let matchIds = try loadMatchId()
    let maxInfo = 100;
    var allMatchInfos = [MatchDto]()
    var failedMatchIds = [String]()
    for matchId in matchIds {
        do {
            let matchInfo = try await fetchMatchInfo(matchId: matchId)
            allMatchInfos.append(matchInfo)
            print("\(allMatchInfos.count*100/maxInfo)%")
        } catch {
            print("Failed to fetch matche info for matchID: \(matchId)\nReason: \(error)")
            failedMatchIds.append(matchId)
            continue
        }
        
        // delay
        try await Task.sleep(nanoseconds: 1400_000_000)
        
        if allMatchInfos.count >= maxInfo {
            print("Stopping: collected \(allMatchInfos.count) match info.")
            break;
        }
    }
    
    saveMatchInfo(allMatchInfos)
}

func stage3() async throws {
    let matchInfos = try loadMatchInfo()
    var champions: [String : ChampionStats] = [:]
    
    for matchInfo in matchInfos {
        let participants: [ParticipantDto] = matchInfo.info.participants
        for participant in participants {
            if let existingChampion = champions[participant.championName] {
                existingChampion.addMatch(participant: participant)
                continue
            }
            let champion = ChampionStats(championName: participant.championName)
            champion.addMatch(participant: participant)
            champions[champion.championName] = champion
        }
    }
    
    try saveChampionStats(champions)
}

func stage4() async throws {
    let data = try await fetchTimeline("NA1_5313388433")
    saveTimeline(data)
}
