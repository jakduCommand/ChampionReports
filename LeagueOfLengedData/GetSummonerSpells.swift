//
//  GetSummonerSpells.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 7/1/25.
//

import Foundation

func downloadAndSaveSummonerSpells() async throws {
    let urlString = "https://ddragon.leagueoflegends.com/cdn/15.13.1/data/en_US/summoner.json"
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
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/summoner_spell.json")
    
    try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    
    try prettyData.write(to: fileURL)
    
    print("Saved summoner spells to \(fileURL.path)")
}

func createMap() throws -> [Int: SummonerSpell] {
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/summoner_spell.json")
    
    let decoder = JSONDecoder()
    let wrapper = try decoder.decode(SummonerDataWrapper.self, from: Data(contentsOf: fileURL))
    
    var spellMap: [Int: SummonerSpell] = [:]
    for spell in wrapper.data.values {
        if let id = Int(spell.key) {
            spellMap[id] = spell
        }
    }
    
    return spellMap
}
struct SummonerSpell: Codable {
    let id: String
    let key: String
    let name: String
    let description: String
    
}

struct SummonerDataWrapper: Codable {
    let data: [String: SummonerSpell]
}
