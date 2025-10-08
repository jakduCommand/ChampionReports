//
//  MatchParser.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/25/25.
//
import Foundation

typealias ChampionRecordLookup = [String:ChampionRecord]

class MatchAnalyzer {
    
public
    
    init(version: String, championList: ChampionListResponse) throws {
        self.version = version
        self.championList = championList
        self.championLookup = buildChampionLookup(championList)
        self.championByPuuid = [:]
        self.championByParticipantid = [:]
        self.championItemBuild = [:]
        self.result = [:]
        do {
            self.summonerSpellLookup = try loadSummonerSpells()
        } catch {
            throw error
        }
    }
    
    func parse(matchId: String, matchInfo: MatchDto, timeline: TimelineDto) async throws -> ChampionRecordLookup {
        
        try await parseMatchInfo(matchInfo: matchInfo)
        
        // puuid -> championId
        self.championByPuuid = mapPuuidToChampionId(matchInfo: matchInfo)
        self.championByParticipantid = mapParticipantIdToChampionId(timeline: timeline, championByPuuid: championByPuuid)
        
        try parseTimeline(timeline: timeline)
        
        return self.result
    }
    
    func parseMatchInfo(matchInfo: MatchDto) async throws {
        for p in matchInfo.info.participants {
            let champion = championLookup[p.championName.lowercased().lolSanitized]
            let championId = champion?.id ?? "unknown"
            let championDetail = try await fetchChampion(name: championId, version: self.version)
            var championRecord = ChampionRecord(championId: championId, championDetail: championDetail)
            
            championRecord.spells = parseSpell(participant: p)
            championRecord.winOrLose = p.win
            self.result[championId] = championRecord
        }
    }
    
    func parseSpell(participant: ParticipantDto) -> Set<String> {
            var spells = Set<String>()
            if let s1 = summonerSpellLookup[participant.summoner1Id],
               let s2 = summonerSpellLookup[participant.summoner2Id] {
                spells.insert(s1)
                spells.insert(s2)
            } else {
                spells = []
            }
            return spells
    }
    
    func parseTimeline(timeline: TimelineDto) throws {
        
        for frame in timeline.info.frames {
            let events = frame.events
                .sorted{ $0.timestamp < $1.timestamp }
                .filter{
                    $0.type == "ITEM_PURCHASED" ||
                    $0.type == "ITEM_UNDO" ||
                    $0.type == "ITEM_DESTROYED"
                }
            let participantFrames = frame.participantFrames
            
            // calculate average Location
            averageLocation(participantFrames: participantFrames, timestamp: frame.timestamp)
            
            // Item build
            purchaseHistory(events: events)
            itemBuild()
            
        }
    }
    
    func averageLocation(participantFrames: [Int: ParticipantFrameDto], timestamp: Int) {
        for (id, pf) in participantFrames {
            guard let championId = self.championByParticipantid[id], var championRecord = self.result[championId] else { continue }
            
            if timestamp < 480_000 {
                if championRecord.averageLocation == (0,0) {
                    championRecord.averageLocation = (Int(pf.position.x), Int(pf.position.y))
                } else {
                    let (oldX, oldY) = championRecord.averageLocation
                    let n = championRecord.locationSamples
                    let newX = (oldX * n + pf.position.x) / (n + 1)
                    let newY = (oldY * n + pf.position.y) / (n + 1)
                    
                    championRecord.averageLocation = (newX, newY)
                    championRecord.locationSamples = n + 1
                    
                    self.result[championId] = championRecord
                }
            }
        }
    }
    
    func purchaseHistory(events: [EventsTimeLineDto]) {
        
        for e in events {
            guard let pid = e.participantId,
                  let champ = championByParticipantid[pid] else { continue }
            
            switch e.type {
            case "ITEM_PURCHASED":
                if let id = e.itemId {
                    self.championItemBuild[champ, default: []].append((id: id, ts: e.timestamp))
                }
            
            case "ITEM_UNDO":
                // pops the last purchased item
                if var seq = self.championItemBuild[champ], !seq.isEmpty {
                    seq.removeLast()
                    self.championItemBuild[champ] = seq
                }
            
            case "ITEM_DESTROYED":
                // "World Atlas" for support itme
                if let id = e.itemId, id == 3865 {
                    if var seq = self.championItemBuild[champ] {
                        // only insert if it's not already in the sequence
                        if !seq.contains(where: { $0.id == 3865}) {
                            seq.insert((id: id, ts: 0), at: 0)
                            self.championItemBuild[champ] = seq
                        }
                    } else {
                        self.championItemBuild[champ] = [(id: id, ts: 0)]
                    }
                }
                
            default:
                break;
            }
        }
    }
    
    func itemBuild() {
        for champ in self.championItemBuild.keys {
            result[champ]?.itemBuild = championItemBuild[champ]!
        }
    }
    
    func laneAndRole() {
        // assign each chmapion's role
        
        // assign Jungle first
        
    }
    
    // map puuid -> championId
    func mapPuuidToChampionId(matchInfo: MatchDto) -> [String:String] {
        var result: [String:String] = [:]
        
        for p in matchInfo.info.participants {
            let championData = championLookup[p.championName.lowercased().filter { $0.isLetter }]
            let championId = championData?.id ?? "unknown"
            
            result[p.puuid] = championId
        }
        
        return result
    }
    
    // map participantId -> championId
    func mapParticipantIdToChampionId(timeline: TimelineDto, championByPuuid: [String: String]) -> [Int:String] {
        var championByParticipantId: [Int:String] = [:]
        for tp in timeline.info.participants {
            if let champ = championByPuuid[tp.puuid] {
                championByParticipantId[tp.participantId] = champ
            }
        }
        return championByParticipantId
    }
    
private
    let version: String
    let championList: ChampionListResponse
    let championLookup: [String: ChampionListData]
    let summonerSpellLookup: [Int: String]
    var championByPuuid: [String: String]
    var championByParticipantid: [Int:String]
    var championItemBuild: [String:[Purchase]]
    var result: ChampionRecordLookup
}


