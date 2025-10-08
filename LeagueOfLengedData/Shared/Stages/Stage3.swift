//
//  Stage3.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/25/25.
//
import Foundation

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
    var count = 0
    let limit = 100 // bind dnumber of match id that would be aggregated.
    let summonerSpellLookupTable = try loadSummonerSpells()
    let version = try await fetchVersion()
    
    /// the reason why I should use this variable is that championName from match history
    /// and championID in ddragon don't match.
    let championList = try await fetchChampionList(version)
    let lookup = buildChampionLookup(championList)
    
    for matchId in matchIds {
        if count >= limit { break }

        
        // load
        guard let matchInfo = try? loadMatchInfo(matchId),
           let timeline = try? loadTimeline(matchId) else {
            continue
        }
        
        
        // Map puuid -> champion id
        var championByPuuid: [String:String] = [:]     // [puuid : champion name]
        for p in matchInfo.info.participants {
            let sanitizedName = p.championName.lowercased().filter { $0.isLetter }
            let championData = lookup[sanitizedName]
            let championId = championData?.id ?? "unknown"
            
            championByPuuid[p.puuid] = championId

            // summoner spells
            var spells = Set<String>()
            if let s1 = summonerSpellLookupTable[p.summoner1Id],
               let s2 = summonerSpellLookupTable[p.summoner2Id] {
                spells.insert(s1)
                spells.insert(s2)
            } else {
                spells = []
            }
            
            //Aggregate champion stats from MatchDto
            if let bucket = champions[championId] {
                bucket.addMatch(participant: p)
                bucket.addSummonerSpell(spells)
            } else {
                let normalized = p.championName.lowercased().filter { $0.isLetter }
                guard let champData = lookup[normalized] else {
                    print(" Could not resolve matchinfo of champion: \(p.championName)")
                    continue
                }
                
                let detail = try await fetchChampion(name: champData.id, version: version)
                let bucket = ChampionStats(championName: champData.name, id: champData.id, version: version, championDetail: detail)
                bucket.addMatch(participant: p)
                bucket.addSummonerSpell(spells)
                champions[championId] = bucket
            }
        }
        
        // Map participantId -> champoin name
        var championByParticipantId: [Int:String] = [:]
        for tp in timeline.info.participants {
            if let champ = championByPuuid[tp.puuid] {
                championByParticipantId[tp.participantId] = champ
            }
        }
        
        
        // ITEM
        // Build per-champoin ordered item sequence for this match
        var championItemBuild: [String:[Purchase]] = [:]
        
        // Flatten. sort by time, and pre-filter to events we care about
        let events = timeline.info.frames
            .flatMap(\.events)
            .sorted{ $0.timestamp < $1.timestamp }
            .filter { $0.type == "ITEM_PURCHASED" || $0.type == "ITEM_UNDO" || $0.type == "ITEM_DESTROYED"}
                
        for e in events {
            guard let pid = e.participantId,
                  let champ = championByParticipantId[pid] else { continue }
                
            switch e.type {
            case "ITEM_PURCHASED":
                if let id = e.itemId {
                    championItemBuild[champ, default: []].append((id: id, ts: e.timestamp))
                }
                
            case "ITEM_UNDO":
                // pops the last purchase
                if var seq = championItemBuild[champ], !seq.isEmpty {
                    seq.removeLast()
                    championItemBuild[champ] = seq
                }
                
            case "ITEM_DESTROYED":
                // "Wolrd Atlas" for support item
                if let id = e.itemId, id == 3865 {
                    if var seq = championItemBuild[champ] {
                        // only insert if it's not already in the sequence
                        if !seq.contains(where: { $0.id == 3865}) {
                            seq.insert((id: id, ts: 0), at: 0)
                            championItemBuild[champ] = seq
                        }
                    } else {
                        championItemBuild[champ] = [(id: id, ts: 0)]
                    }
                }
                
            default:
                break
            }
        }
        
        // call ingestBuildsequence
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/ddragon/item.json")
        try ItemIndex.shared.load(from: fileURL)
        for champ in championItemBuild.keys {
            if let bucket = champions[champ] {
                bucket.ingestBuildSequence(championItemBuild[champ] ?? [])
            } else {
                let normalized = champ.lowercased().filter { $0.isLetter }
                guard let champData = lookup[normalized] else {
                    print(" Could not resolve timeline of champion: \(champ)")
                    continue
                }
                
                let detail = try await fetchChampion(name: champData.id, version: version)
                let bucket = ChampionStats(championName: champData.name, id: champData.id, version: version, championDetail: detail)
                
                bucket.ingestBuildSequence(championItemBuild[champ] ?? [])
                champions[bucket.championName] = bucket
            }
        }
        count += 1
    }
    
    for champ in champions {
        let champName = champ.key
        let champStats = champ.value
    
        try saveChampionStats(champName, champStats)
    }

}
