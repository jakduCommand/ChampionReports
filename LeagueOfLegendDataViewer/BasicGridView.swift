//
//  BasicGridView.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/6/25.
//

import SwiftUI

struct BasicGridView: View {
    let version: String
    let basicItems: [Int]
    
    private func iconURL(for id: Int) -> URL? {
        URL(string: "https://ddragon.leagueoflegends.com/cdn/\(version)/img/item/\(id).png")
    }
    
    let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]
    
    var body: some View {
        
        if version.isEmpty || basicItems.isEmpty {
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading items...").font(.caption)
            }
            .padding()
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(basicItems, id: \.self) { id in
                    VStack(spacing: 6) {
                        AsyncImage(url: iconURL(for: id)) { image in
                            image
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 48, height: 48)
                        
                        Text("\(id)")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
        }
    }
}
