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
    case fetchMatchInfoAndTimeline = 2
    case championStats = 3
    case fetchTimeline = 4
    case getSummonerSpells = 10
    case getItemInfo = 11
}


Task {
    
    let stage = Stage.championStats
    
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
    case .fetchMatchInfoAndTimeline:
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
            //try await stage4()
            exit(0)
        } catch {
            //print("error", error)
            exit(1)
        }
    case .getSummonerSpells:
        do{
            let version = "15.18.1"
            try await downloadAndSaveSummonerSpells(version)
            
            exit(0)
        } catch {
            exit(1)
        }
    case .getItemInfo:
        do {
            try await downloadItemData()
            
            let fileURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents/lol_data/ddragon/item.json")
            try ItemIndex.shared.load(from: fileURL)
            print("Item index built: boots=\(ItemIndex.shared.boots.count), legendary=\(ItemIndex.shared.legendary.count), mythic=\(ItemIndex.shared.mythic.count)")
        
            
            exit(0)
        } catch {
            exit(1)
        }
    default:
        print("Invalid Stage")
    }
    
    
}

RunLoop.main.run()
