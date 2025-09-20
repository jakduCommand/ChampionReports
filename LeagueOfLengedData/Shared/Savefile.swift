//
//  Savefile.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/8/25.
//
import Foundation

func save<T: Codable>(_ object: T, to fileURL: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(object)
    
    try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
    )
    
    
    try data.write(to: fileURL)
}
