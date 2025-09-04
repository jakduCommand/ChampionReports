//
//  LeagueOfLegendDataViewerApp.swift
//  LeagueOfLegendDataViewer
//
//  Created by Jungwoon Ko on 9/1/25.
//

import SwiftUI

@main
struct LeagueOfLegendDataViewerApp: App {
    @State private var loadError: String?
    @State private var legendaryIds: [Int] = []
    @State private var bootsIds: [Int] = []
    @State private var starteritemIds: [Int] = []
    @State private var version: String = ""
    var body: some Scene {
        WindowGroup {
            ScrollView() {
                Text("Legendary Items")
                    .font(.headline)
                    .bold()
                
                LegendaryGridView(
                    version: ItemIndex.shared.version,
                    legendaryIds: legendaryIds
                )
                
                Text("Boots")
                    .font(.headline)
                    .bold()
                
                BootsGridView(
                    version: ItemIndex.shared.version,
                    bootsIds: bootsIds
                )
                
                Text("Starter Items")
                    .font(.headline)
                    .bold()
                
                StarterItemGridView(
                    version: ItemIndex.shared.version,
                    starterItemIds: starteritemIds
                )
            }
            .task {
                await initItemIndex()
                legendaryIds = Array(ItemIndex.shared.legendary).sorted()
                bootsIds = Array(ItemIndex.shared.boots).sorted()
                starteritemIds = Array(ItemIndex.shared.starters).sorted()
                version = ItemIndex.shared.version
                print("Legendary count:", legendaryIds.count)
            }
            .alert("Failed to load items", isPresented: .constant(loadError != nil), actions: {
                    Button("OK") { loadError = nil }
                }, message: {
                    Text(loadError ?? "")
                }
            )
            .padding()
            
        }
    }

    @MainActor
    private func initItemIndex() async {
        do {
            guard let url = Bundle.main.url(forResource: "item", withExtension: "json") else {
                throw URLError(.fileDoesNotExist)
            }
            try ItemIndex.shared.load(from: url)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
