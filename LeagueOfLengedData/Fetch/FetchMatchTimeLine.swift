//
//  FetchMatchTimeLine.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 8/5/25.
//
import Foundation

func fetchTimeline(_ MatchId: String) async throws -> TimelineDto {
    let urlString = "https://americas.api.riotgames.com/lol/match/v5/matches/\(MatchId)/timeline?api_key=\(RiotAPI.APIKEY)"
    
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)}
    

    var request = URLRequest(url: url)
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Accept-Charset")
    request.setValue("https://developer.riotgames.com", forHTTPHeaderField: "Origin")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    var timelineData: TimelineDto
    timelineData = try JSONDecoder().decode(TimelineDto.self, from: data)
    return timelineData
}

func saveTimeline(_ matchId: String, _ timelineData: TimelineDto) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    
    do {
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("/Documents/lol_data/timeline/timeline_\(matchId).json")
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let data = try encoder.encode(timelineData)
        try data.write(to: fileURL)
        print("Saved timeline to \(fileURL.path)")
    } catch {
        print("Faild to save timeline: ", error)
    }
}

func loadTimeline(_ matchId: String) throws -> TimelineDto {
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("/Documents/lol_data/timeline/timeline_\(matchId).json")
    
    let data = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    let timelineData = try decoder.decode(TimelineDto.self, from: data)
    
    return timelineData
}

struct TimelineDto: Codable {
    let metadata: MetadataTimeLineDto
    let info: InfoTimeLineDto
}

struct MetadataTimeLineDto: Codable {
    let dataVersion: String
    let matchId: String
    let participants: [String]
}

struct InfoTimeLineDto: Codable {
    let endOfGameResult: String
    let frameInterval: Int
    let gameId: Int
    let participants: [ParticipantTimeLineDto]
    let frames: [FrameTimeLineDto]
}

struct ParticipantTimeLineDto: Codable {
    let participantId: Int
    let puuid: String
}

struct FrameTimeLineDto: Codable {
    let events: [EventsTimeLineDto]
    let participantFrames: [Int: ParticipantFrameDto]
    let timestamp: Int
}

struct EventsTimeLineDto: Codable {
    let timestamp: Int
    let realTimestamp: Int?
    let levelupType: String?
    let wardType: String?
    let participantId: Int?
    let creatorId: Int?
    let skillSlot: Int?
    let level: Int?
    let itemId: Int?
    let type: String
}

struct ParticipantFrameDto: Codable {
    let championStats: ChampionStatsDto
    let currentGold: Int
    let damageStats: DamageStatsDto
    let goldPerSecond: Int
    let jungleMinionsKilled: Int
    let level: Int
    let minionsKilled: Int
    let participantId: Int
    let position: PositionDto
    let timeEnemySpentControlled: Int
    let totalGold: Int
    let xp: Int
}

struct ChampionStatsDto: Codable {
    let abilityHaste: Int
    let abilityPower: Int
    let armor: Int
    let armorPen: Int
    let armorPenPercent: Int
    let attackDamage: Int
    let attackSpeed: Int
    let bonusArmorPenPercent: Int
    let bonusMagicPenPercent: Int
    let ccReduction: Int
    let cooldownReduction: Int
    let health: Int
    let healthMax: Int
    let healthRegen: Int
    let lifesteal: Int
    let magicPen: Int
    let magicPenPercent: Int
    let magicResist: Int
    let movementSpeed: Int
    let omnivamp: Int
    let physicalVamp: Int
    let power: Int
    let powerMax: Int
    let powerRegen: Int
    let spellVamp: Int
}

struct DamageStatsDto: Codable {
    let magicDamageDone: Int
    let magicDamageDoneToChampions: Int
    let magicDamageTaken: Int
    let physicalDamageDone: Int
    let physicalDamageDoneToChampions: Int
    let physicalDamageTaken: Int
    let totalDamageDone: Int
    let totalDamageDoneToChampions: Int
    let totalDamageTaken: Int
    let trueDamageDone: Int
    let trueDamageDoneToChampions: Int
    let trueDamageTaken: Int
}

struct PositionDto: Codable {
    let x: Int
    let y: Int
}
