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
    @State private var basicItemIds: [Int] = []
    @State private var epicItemIds: [Int] = []
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
                
                Text("Basic Items")
                    .font(.headline)
                    .bold()
                
                BasicGridView(
                    version: ItemIndex.shared.version,
                    basicItems: basicItemIds
                )
                
                Text("Epic Items")
                    .font(.headline)
                    .bold()
                
                EpicGridView(
                    version: ItemIndex.shared.version,
                    epicItems: epicItemIds
                )
            }
            .task {
                await initItemIndex()
                legendaryIds = Array(ItemIndex.shared.legendary).sorted()
                bootsIds = Array(ItemIndex.shared.boots).sorted()
                starteritemIds = Array(ItemIndex.shared.starters).sorted()
                version = ItemIndex.shared.version
                basicItemIds = Array(ItemIndex.shared.basic).sorted()
                epicItemIds = Array(ItemIndex.shared.epic).sorted()
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
