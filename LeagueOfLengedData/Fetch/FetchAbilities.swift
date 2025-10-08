//
//  FetchAbilities.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/20/25.
//
import Foundation

struct ChampionDataWrapper: Codable {
    var type: String
    var format: String
    var version: String
    var data: [String: Champion]
}

struct Champion: Codable {
    let id: String
    let key: String
    let name: String
    let title: String
    let blurb: String
    let info: Info
    let image: Image
    let spells: [Spell]
    let passive: Passive
}

struct Info: Codable {
    let attack: Int
    let defense: Int
    let magic: Int
    let difficulty: Int
}

struct Image: Codable {
    let full: String
    let sprite: String
    let group: String
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}

struct Spell: Codable {
    let id: String
    let name: String
    let description: String
    let image: Image
}


struct Passive: Codable {
    let name: String
    let description: String
    let image: Image
}

func fetchChampion(name: String, version: String) async throws -> Champion {
    
    let url = URL(string: "https://ddragon.leagueoflegends.com/cdn/\(version)/data/en_US/champion/\(name).json")!
    let (data, _) = try await URLSession.shared.data(from: url)
    
    let decoded = try JSONDecoder().decode(ChampionDataWrapper.self, from: data)
    
    guard let champion = decoded.data[name] else {
        throw URLError(.badServerResponse)
    }
    
    return champion
}

func fetchVersion() async throws -> String {

    let url = URL(string: "https://ddragon.leagueoflegends.com/api/versions.json")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoded: [String] = try JSONDecoder().decode([String].self, from: data)
    guard let version = decoded.first else {
        throw URLError(.badServerResponse)
    }
    
    return version

}
