//
//  MatchResult.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/26/25.
//

// result tamplate for aggregation
import Foundation

struct ChampionRecord {
    
    init(championId: String, championDetail: Champion) {
        self.championId = championId
        self.winOrLose = false
        self.itemBuild = []
        self.averageLocation = (0, 0)
        self.championDetail = championDetail
        self.spells = []
        self.lane = ""
        self.powerCurve = [:]
        self.locationSamples = 0
    }
    
    var championId: String
    var winOrLose: Bool
    var itemBuild: [Purchase]
    var averageLocation: (Int, Int)
    var championDetail: Champion
    var spells: Set<String>
    var lane: String
    var powerCurve: [Int:Int]
    var locationSamples: Int
}
