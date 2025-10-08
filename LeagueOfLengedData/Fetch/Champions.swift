//
//  Champions.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 7/2/25.
//

import Foundation

typealias Purchase = (id: Int, ts: Int)

struct ItemFrequencies: Codable {
    var allItems: [Int: Int] = [:]
    var starters: [Set<Int>: Int] = [:]
    var boots: [Int: Int] = [:]
    var firstCore: [Int : Int] = [:]
    var secondCore: [Int : Int] = [:]
    var thirdCore: [Int : Int] = [:]
    var fourthCore: [Int : Int] = [:]
    var fifthCore: [Int : Int] = [:]
    var sixthCore: [Int : Int] = [:]
}

struct Record: Codable {
    var match: Int
    var win: Int
    var lose: Int
}

class ChampionStats: Codable {
    let championName: String
    let id: String
    let version: String
    let championDetail: Champion
    
    var totalGames: Int = 0
    var totalWins: Int = 0
    var laneFrequency: [String: Int] = [:]
    var winRateByLane: [String: [String: Int]] = [:]
    
    // Items
    var items = ItemFrequencies()
    
    // summoner spells
    var spellFrequency: [Set<String> : Int] = [:]
    
    // Rune Page
    var fullRunePageFrequency: [RunePage: Int] = [:]
    
    init(championName: String, id:String, version: String, championDetail: Champion) {
        self.championName = championName
        self.version = version
        self.championDetail = championDetail
        self.id = id
    }
    
    func ingestBuildSequence(_ sequence: [Purchase]) {
        var boots: Int?
        var starters = Set<Int>()
        var cores: [Int] = []
        var nonTrinketPurchaseCount = 0;
        for purchase in sequence {
            let itemId = purchase.id
            if ItemIndex.shared.isTrinket(itemId) {
                continue
            }
            else if ItemIndex.shared.isStarter(itemId), purchase.ts < 60000, nonTrinketPurchaseCount <= 2 {
                starters.insert(itemId)
            }
            else if ItemIndex.shared.isBoots(itemId), boots == nil {
                boots = itemId
            }
            else if ItemIndex.shared.isLegendary(itemId) {
                cores.append(itemId)
            }
            nonTrinketPurchaseCount += 1
        }
        
        if let bs = boots { items.boots[bs, default: 0] += 1}
        
        if !starters.isEmpty {
            items.starters[starters, default: 0] += 1
        }
        
        if let firstCore = cores.dropFirst(0).first { items.firstCore[firstCore, default: 0] += 1 }
        if let secondCore = cores.dropFirst(1).first { items.secondCore[secondCore, default: 0] += 1 }
        if let thirdCore = cores.dropFirst(2).first { items.thirdCore[thirdCore, default: 0] += 1 }
        if let fourthCore = cores.dropFirst(3).first { items.fourthCore[fourthCore, default: 0] += 1 }
        if let fifthCore = cores.dropFirst(4).first { items.fifthCore[fifthCore, default: 0] += 1 }
        if let sixthCore = cores.dropFirst(5).first { items.sixthCore[sixthCore, default: 0] += 1 }
    }
    
    func addSummonerSpell(_ spell: Set<String>) {
        spellFrequency[spell, default: 0] += 1
    }
    
    func addMatch(participant: ParticipantDto) {
        totalGames += 1
        if participant.win {
            totalWins += 1
        }
        
        // Track items
        let pitems = [
            participant.item0,
            participant.item1,
            participant.item2,
            participant.item3,
            participant.item4,
            participant.item5,
            participant.item6
        ]
        
        for item in pitems where item != 0 {
            items.allItems[item, default: 0] += 1
        }
        
        // Track Runes
        let primaryStyle = participant.perks.styles[0].style
        let subStyle = participant.perks.styles[1].style
        
        let primaryPerks = participant.perks.styles[0].selections.map { $0.perk }
        let subPerks = participant.perks.styles[1].selections.map { $0.perk }
        
        if primaryPerks.count == 4 && subPerks.count >= 2 {
            let runePage = RunePage(
                primaryStyle: primaryStyle,
                primaryPerks: PerkBlock(perk1: primaryPerks[0], perk2: primaryPerks[1], perk3: primaryPerks[2], perk4: primaryPerks[3]),
                subStyle: subStyle,
                subPerks: SubPerkBlock(perk1: subPerks[0], perk2: subPerks[1])
            )
            
            fullRunePageFrequency[runePage, default: 0] += 1
        }
        
    }
    
    var winRate: Double {
        return totalGames == 0 ? 0 : Double(totalWins) / Double(totalGames)
    }
}

func saveAllChampionStats(_ stats: [String: ChampionStats]) throws {
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    do {
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/Champion_stats/stats.json")
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let data = try encoder.encode(stats)
        try data.write(to: fileURL)
        print("Saved champion stats to \(fileURL.path)")
    } catch {
        print("Faild to save match info: ", error)
    }
}

func saveChampionStats(_ name: String, _ stats: ChampionStats) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    do {
        let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/Champion_stats/\(name).json")
        
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let data = try encoder.encode(stats)
        try data.write(to: fileURL)
        print("Saved champion stats to \(fileURL.path)")
    } catch {
        print("Failed to save match Info of \(name): ", error)
    }
}

func loadChampionStats(from path: URL) throws -> [String: ChampionStats] {
    let decoder = JSONDecoder()
    let data = try Data(contentsOf: path)
    return try decoder.decode([String: ChampionStats].self, from: data)
}

struct PerkRowMap {
    static let data: [Int: (styleId: Int, row: Int)] = [
        // Version Patch 15.13.1
        // Domination
        8112: (8100, 0), //Electrocute
        8128: (8100, 0), //DarkHarvest
        9923: (8100, 0), //HailOfBlades
        8126: (8100, 1), //CheapShot
        8139: (8100, 1), //TasteOfBlood
        8143: (8100, 1), //SuddenImpact
        8137: (8100, 2), //SixthSense
        8140: (8100, 2), //GrislyMementos
        8141: (8100, 2), //DeepWard
        8135: (8100, 3), //TreasureHunter
        8105: (8100, 3), //RelentlessHunter
        8106: (8100, 3), //UltimateHunter
        
        // Inspiration
        8351: (8300, 0), //GlacialAugment
        8360: (8300, 0), //UnsealedSpellbook
        8369: (8300, 0), //FirstStrike
        8306: (8300, 1), //HextechFlashtraption
        8304: (8300, 1), //MagicalFootwear
        8321: (8300, 1), //CashBack
        8313: (8300, 2), //PerfectTiming
        8352: (8300, 2), //TimeWarpTonic
        8345: (8300, 2), //BiscuitDelivery
        8347: (8300, 3), //CosmicInsight
        8410: (8300, 3), //ApproachVelocity
        8316: (8300, 3), //JackOfAllTrades
        
        // Precision
        8005: (8000, 0), //PressTheAttack
        8008: (8000, 0), //LethalTemp
        8021: (8000, 0), //FleetFootwork
        8010: (8000, 0), //Conqueror
        9101: (8000, 1), //AbsorbLife
        9111: (8000, 1), //Triumph
        8009: (8000, 1), //PresenceOfMind
        9104: (8000, 2), //LegendAlacrity
        9105: (8000, 2), //LegendHaste
        9103: (8000, 2), //LegendBloodLine
        8014: (8000, 3), //CoupDeGrace
        8017: (8000, 3), //CutDown
        8299: (8000, 3), //LastStand
        
        // Resolve
        8437: (8400, 0), //GraspOfTheUndying
        8439: (8400, 0), //Aftershock
        8465: (8400, 0), //Guardian
        8446: (8400, 1), //Demolish
        8463: (8400, 1), //FontOfLife
        8401: (8400, 1), //ShieldBash
        8429: (8400, 2), //Conditioning
        8444: (8400, 2), //SecondWind
        8473: (8400, 2), //BonePlating
        8451: (8400, 3), //Overgrowth
        8453: (8400, 3), //Revitalize
        8242: (8400, 3), //Unflinching
        
        // Sorcery
        8214: (8200, 0), //SummonAery
        8229: (8200, 0), //ArcaneComet
        8230: (8200, 0), //PhaseRush
        8224: (8200, 1), //NullifyingOrb
        8226: (8200, 1), //ManaflowBand
        8275: (8200, 1), //NimbusCloak
        8210: (8200, 2), //Transcendence
        8234: (8200, 2), //Celerity
        8233: (8200, 2), //AbsoluteFocus
        8237: (8200, 3), //Scorch
        8232: (8200, 3), //Waterwalking
        8236: (8200, 3) //GatheringStorm
    ]
}

struct PerkBlock: Hashable, Codable {
    let perk1: Int
    let perk2: Int
    let perk3: Int
    let perk4: Int
}

struct SubPerkBlock: Hashable, Codable {
    let perk1: Int
    let perk2: Int
}

struct RunePage: Hashable, Codable {
    let primaryStyle: Int
    let primaryPerks: PerkBlock
    let subStyle: Int
    let subPerks: SubPerkBlock
}
