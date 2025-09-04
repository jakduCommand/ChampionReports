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

func readItemData() throws -> ItemDataWrapper {
    let fileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/lol_data/ddragon/item.json")
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(ItemDataWrapper.self, from: data)
}

struct ItemDataWrapper: Codable {
    let type: String
    let version: String
    let data: [String: ItemDetail]
}

struct ItemDetail: Codable {
    let name: String
    let plaintext: String?
    let description: String?
    let tags: [String]?
    let into: [String]?
    let from: [String]?
    let depth: Int?
    let maps: [String: Bool]?
    let inStore: Bool?
    let gold: GoldInfo
}

struct GoldInfo: Codable {
    let base: Int
    let purchasable: Bool
    let sell: Int
    let total: Int
}

final class ItemIndex: Codable {
    static let shared = ItemIndex()
    private init() {}
    
    private(set) var version: String = ""
    
    // Raw map for any extra info you might need later
    private(set) var items: [Int: ItemDetail] = [:]
    
    // Category sets
    private(set) var boots: Set<Int> = []
    private(set) var trinkets: Set<Int> = []
    private(set) var consumables: Set<Int> = []
    private(set) var starters: Set<Int> = []
    private(set) var completed: Set<Int> = []
    private(set) var legendary: Set<Int> = []
    private(set) var mythic: Set<Int> = []
    
    // Convenience checks
    func isBoots(_ id: Int) -> Bool { boots.contains(id) }
    func isTrinket(_ id: Int) -> Bool {
        trinkets.contains(id)
    }
    func isConsumable(_ id: Int) -> Bool {
        consumables.contains(id)
    }
    func isStarter(_ id: Int) -> Bool {
        starters.contains(id)
    }
    func isCompleted(_ id: Int) -> Bool {
        completed.contains(id)
    }
    func isLegendary(_ id: Int) -> Bool {
        legendary.contains(id)
    }
    func isMythic(_ id: Int) -> Bool {
        mythic.contains(id)
    }
    
    func isPurchasableNow(_ item: ItemDetail, id: Int, onMap mapId: String = "11") -> Bool {
        guard id <= 9999 else { return false }
        guard item.gold.purchasable else { return false }
        if let maps = item.maps, maps[mapId] != true { return false }
        //if item.inStore != nil { return false }
        return true
    }
    
    
    // Load & index from a URL on disk
    func load(from fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        let wrapper = try JSONDecoder().decode(ItemDataWrapper.self, from: data)
        
        version = wrapper.version
        
        // Clear old data
        items.removeAll()
        boots.removeAll()
        trinkets.removeAll()
        consumables.removeAll()
        starters.removeAll()
        completed.removeAll()
        legendary.removeAll()
        mythic.removeAll()
        
        // Populate
        for (key, detail) in wrapper.data {
            guard let id = Int(key) else { continue }
            items[id] = detail
            
            let tags = Set(detail.tags ?? [])
            
            // Boots: tag "Boots"
            if tags.contains("Boots")
                || detail.name.localizedCaseInsensitiveContains("Gunmetal Greaves"){
                if isPurchasableNow(detail, id: id) {
                    boots.insert(id)
                }
            }
            
            // Trinkets: stable ids + tag-based fallback
            if [3340, 3363, 3364].contains(id) || tags.contains("Trinket") {
                if isPurchasableNow(detail, id: id) {
                    trinkets.insert(id)
                }
            }
            
            // Consumables: tag "Consumable" or "Potion" in plaintext/name (fallback)
            if tags.contains("Consumable")
                || detail.name.localizedCaseInsensitiveContains("Potion")
                || (detail.plaintext ?? "").localizedCaseInsensitiveContains("consume") {
                if isPurchasableNow(detail, id: id) {
                    consumables.insert(id)
                }
            }
            
            // Completed: cannot build further
            let isCompleted = (detail.into == nil || detail.into?.isEmpty == true)
            if isCompleted {
                if isPurchasableNow(detail, id: id) {
                    completed.insert(id)
                }
            }
            
            // Starters
            // depth == 1 and totla <= 500 and not trinket
            if (detail.depth ?? 0) <= 1,
               detail.gold.total <= 500,
               !trinkets.contains(id) {
                if isPurchasableNow(detail, id: id) {
                    starters.insert(id)
                }
            }
            
            // Mythic: riot remove mythic items. dummy data.
            let description = (detail.description ?? "")
            if description.localizedCaseInsensitiveContains(("Mythic Passive")) {
                if isPurchasableNow(detail, id: id) {
                    mythic.insert(id)
                }
            }
            
            // Legendary: completed, not boots/consumable/trinket, not mythic.
            if completed.contains(id),
               !boots.contains(id),
               !trinkets.contains(id),
               !consumables.contains(id),
               !mythic.contains(id),
               (detail.gold.total >= 1500
                || detail.name.localizedCaseInsensitiveContains("Zaz'Zak's Realmspike")
                || detail.name.localizedCaseInsensitiveContains("Bloodsong")
                || detail.name.localizedCaseInsensitiveContains("Solstice Sleigh")
                || detail.name.localizedCaseInsensitiveContains("Dream Maker")
                || detail.name.localizedCaseInsensitiveContains("Celestial Opposition")
               ) {
                if isPurchasableNow(detail, id: id) {
                    legendary.insert(id)
                }
            }
        }
        
    }
    
}
