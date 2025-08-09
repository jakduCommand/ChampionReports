//
//  main.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 6/19/25.
//

import Foundation

enum Stage: Int {
    case fetchEntries = 0
    case fetchMatches = 1
    case fetchMatchInfo = 2
    case championStats = 3
    case fetchTimeline = 4
    case getSummonerSpells = 10
}


Task {
    
    let stage = Stage.fetchTimeline
    
    switch stage {
    case .fetchEntries:
        do {
            try await stage0()
            exit(0)
        } catch {
            print("Error: ", error)
            exit(1)
        }
    case .fetchMatches:
        do {
            try await stage1()
            exit(0)
        } catch {
            print("Error", error)
            exit(1)
        }
    case .fetchMatchInfo:
        do {
            try await stage2()
            exit(0)
        } catch {
            print("Error", error)
            exit(1)
        }
    case .championStats:
        do {
            try await stage3()
            exit(0)
        } catch {
            print("error", error)
            exit(1)
        }
    case .fetchTimeline:
        do {
            try await stage4()
            exit(0)
        } catch {
            print("error", error)
            exit(1)
        }
    case .getSummonerSpells:
        do{
            try await downloadAndSaveSummonerSpells()
            exit(0)
        } catch {
            exit(1)
        }
    default:
        print("Invalid Stage")
    }
    
    
}

RunLoop.main.run()
