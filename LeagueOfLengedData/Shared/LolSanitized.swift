//
//  LolSanitized.swift
//  LeagueOfLengedData
//
//  Created by Jungwoon Ko on 9/20/25.
//

// change any champion's name into id(string) so that it matches
// Riot's JSON file names
// ex) Bel'Veth -> Belveth
extension String {
    var lolSanitized: String {
        return self.lowercased().filter{ $0.isLetter }
    }
}
