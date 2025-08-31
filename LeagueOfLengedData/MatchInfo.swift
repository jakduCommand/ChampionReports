//
//  MatchInfo.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 6/25/25.
//

import Foundation

func fetchMatchInfo(matchId: String) async throws -> MatchDto {
    let urlString = "https://americas.api.riotgames.com/lol/match/v5/matches/\(matchId)?api_key=\(RiotAPI.APIKEY)"
    
    guard let url = URL(string: urlString) else { throw URLError(.badURL)}
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.1", forHTTPHeaderField: "User-Agent")
    request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Accept-Charset")
    request.setValue("https://developer.riotgames.com", forHTTPHeaderField: "Origin")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    
    guard httpResponse.statusCode == 200 else {
        let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
        print("Http \(httpResponse.statusCode): \(body)")
        throw URLError(.badServerResponse)
    }
    
    let decoder = JSONDecoder()
    return try decoder.decode(MatchDto.self, from: data)
}


func loadMatchId() throws -> [String] {
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/match_ids.json")
    
    let data = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    let matchIds = try decoder.decode([String].self, from: data)
    
    return matchIds
}


func saveMatchInfo(_ matchID: String, _ matchInfo: MatchDto) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    
    do {
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("/Documents/lol_data/match_info/matchInfo_\(matchID).json")
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let data = try encoder.encode(matchInfo)
        try data.write(to: fileURL)
        print("Saved match info to \(fileURL.path)")
    } catch {
        print("Faild to save match info: ", error)
    }
}

func loadMatchInfo(_ matchID: String) throws -> MatchDto{
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("/Documents/lol_data/match_info/matchInfo_\(matchID).json")
    
    let data = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    let matchDtos = try decoder.decode(MatchDto.self, from: data)
    
    return matchDtos
}

//func correctedLaneIfValid(from participants: [ParticipantDto]) -> [String]? {
//    // TODO
//    let smiteID = 11
//    var correctedLanes: [String] = []
//    var smiteCount = 0
//    
//    for participant in participants {
//        let hasSmite = (participant.summoner1Id == smiteID || participant.summoner2Id == smiteID)
//        if hasSmite {
//            smiteCount += 1
//        }
//        
//        // Correct lane
//    }
//    return nil
//}


enum Role: String, CaseIterable {
    case top = "TOP"
    case jungle = "JUNGLE"
    case mid = "MID"
    case bottom = "BOTTOM"
    case support = "SUPPORT"
}


struct MatchDto: Codable {
    let metadata: MetadataDto
    let info: InfoDto
}

struct MetadataDto: Codable {
    let dataVersion: String
    let matchId: String
    let participants: [String]
}

struct InfoDto: Codable {
    let endOfGameResult: String
    let gameMode: String
    let gameType: String
    let participants: [ParticipantDto]
}

struct ParticipantDto: Codable {
    let championName: String
    let item0: Int
    let item1: Int
    let item2: Int
    let item3: Int
    let item4: Int
    let item5: Int
    let item6: Int
    let lane: String
    let perks: PerksDto
    let summoner1Id: Int
    let summoner2Id: Int
    let win: Bool
    let puuid: String
}

struct PerksDto: Codable {
    let statPerks: PerksStatsDto
    let styles: [PerkStyleDto]
}

struct PerksStatsDto: Codable {
    let defense: Int
    let flex: Int
    let offense: Int
}

struct PerkStyleDto: Codable {
    let description: String
    let selections: [PerkStyleSelectionDto]
    let style: Int
}

struct PerkStyleSelectionDto: Codable {
    let perk: Int
    let var1: Int
    let var2: Int
    let var3: Int
}
