//
//  GetSummonerSpells.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 7/1/25.
//

import Foundation

func downloadAndSaveSummonerSpells(_ version: String) async throws {
    let urlString = "https://ddragon.leagueoflegends.com/cdn/\(version)/data/en_US/summoner.json"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    // decode and re-encode with pretytPrinted
    let json = try JSONSerialization.jsonObject(with: data, options: [])
    let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
    
    // save to file
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/ddragon/summoner_spell.json")
    
    try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    
    try prettyData.write(to: fileURL)
    
    print("Saved summoner spells to \(fileURL.path)")
}

func readSummonerSpellData() throws -> SummonerDataWrapper {
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/ddragon/summoner_spell.json")
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(SummonerDataWrapper.self, from: data)
}

func loadSummonerSpells() throws -> [Int: String] {
    let wrapper = try readSummonerSpellData()
    
    var lookup: [Int: String] = [:]
    for detail in wrapper.data.values {
        if let intkey = Int(detail.key) {
            lookup[intkey] = detail.image.full
        }
    }
    
    return lookup
}

struct SummonerDataWrapper: Codable {
    let type: String
    let version: String
    let data: [String: SummonerSpell]
}

struct SummonerSpell: Codable {
    let id: String
    let name: String
    let description: String
    let tooltip: String
    let key: String
    let summonerLevel: Int
    let image: SummonerSpellImage
}

struct SummonerSpellImage: Codable {
    let full: String
}


