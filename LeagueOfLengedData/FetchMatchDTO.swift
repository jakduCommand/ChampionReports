//
//  FetchMatchDTO.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 6/24/25.
//
import Foundation

func fetchMatchIDs(for puuid: String) async throws -> [String] {
    
    let urlString = "https://americas.api.riotgames.com/lol/match/v5/matches/by-puuid/\(puuid)/ids?start=0&count=50&api_key=\(RiotAPI.APIKEY)"
    
    guard let url = URL(string: urlString) else { throw URLError(.badURL)}
    
    var request = URLRequest(url: url)
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
    request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Accept-Charset")
    request.setValue("https://developer.riotgames.com", forHTTPHeaderField: "Origin")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    var matchIDs: [String] = []
    matchIDs = try JSONDecoder().decode([String].self, from: data)
    return matchIDs
}

func loadPuuids() throws -> [String] {
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/puuids.json")
    
    let data = try Data(contentsOf: fileURL)
    let puuidList = try JSONDecoder().decode(PuuidList.self, from: data)
    return puuidList.puuids
}

func saveMatchIDs(_ matchIDs: [String]) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    
    do {
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/match_ids.json")
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let data = try encoder.encode(matchIDs)
        try data.write(to: fileURL)
        print("Saved match IDs to \(fileURL.path)")
    } catch {
        print("Failed to save match IDs:", error)
    }
}
