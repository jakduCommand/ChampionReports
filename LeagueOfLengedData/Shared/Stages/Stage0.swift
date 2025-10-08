//
//  Stage0.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/25/25.
//
import Foundation

/**
 * Stage 0 is the first step to collect league of legedns data. It collect puuid of certian tier.
 */
func stage0() async throws {
    let data = try await fetchLeagueListDTO()
    saveLeagueListDTO(data)
    savePuuid(data)
}
