//
//  FetchItemList.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 8/19/25.
//
import Foundation

func downloadItemData() async throws {
    let urlString = "https://ddragon.leagueoflegends.com/cdn/15.16.1/data/en_US/item.json"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    // Save to local file
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/ddragon/item.json")
    
    try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )
    
    // prettifyItemJson
    let obj = try JSONSerialization.jsonObject(with: data, options: [])
    let pretty = try JSONSerialization.data(
        withJSONObject: obj,
        options: [.prettyPrinted, .sortedKeys]
    )
    
    try pretty.write(to: fileURL)
    print("Saved item.json to \(fileURL.path)")
}
