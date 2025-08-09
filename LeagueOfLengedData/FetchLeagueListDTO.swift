//
//  GetEntries.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 6/23/25.
//
import Foundation

func fetchLeagueListDTO() async throws -> LeagueListDTO {
    let url = URL(string: "https://na1.api.riotgames.com/lol/league/v4/masterleagues/by-queue/RANKED_SOLO_5x5?api_key=\(RiotAPI.APIKEY)")!

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Accept-Charset")
    request.setValue("https://developer.riotgames.com", forHTTPHeaderField: "Origin")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(LeagueListDTO.self, from: data)
    return decoded
}

func saveLeagueListDTO(_ data: LeagueListDTO) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    
    do {
        let encodedData = try encoder.encode(data)
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/LeagueListDTO.json")
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        try encodedData.write(to: fileURL)
        print("Saved LeagueListDTO to \(fileURL.path)")
    } catch {
        print("Failed to save LeagueListDTO:", error)
    }
}

func savePuuid(_ data: LeagueListDTO) {
    let puuidList = data.entries.map { $0.puuid }
    let puuidWrapper = PuuidList(puuids: puuidList)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    
    do {
        let encodedData = try encoder.encode(puuidWrapper)
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/puuids.json")
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        try encodedData.write(to: fileURL)
        print("Saved puuids to \(fileURL.path)")
    } catch {
        print("Failed to save puuids", error)
    }
    
}

struct LeagueListDTO: Codable {
    let leagueId: String
    let entries: [LeagueItemDTO]
    let tier: String
    let name: String
    let queue: String
}

struct LeagueItemDTO: Codable {
    let freshBlood: Bool
    let wins: Int
    let inactive: Bool
    let veteran: Bool
    let hotStreak: Bool
    let rank: String
    let leaguePoints: Int
    let losses: Int
    let puuid: String
}

struct PuuidList: Codable {
    let puuids: [String]
}
