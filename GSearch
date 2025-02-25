import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    
    let gamesSites = [
        "https://www.pcgamer.com", "https://www.gamesradar.com", "https://www.ign.com", "https://www.rockpapershotgun.com", "https://www.fanbyte.com",
        "https://www.gameinformer.com", "https://www.gamespot.com", "https://www.vg247.com", "https://www.gamasutra.com", "https://www.destructoid.com",
        "https://www.kotaku.com", "https://www.polygon.com", "https://www.venturebeat.com", "https://www.metacritic.com/game", "https://www.gamefaqs.gamespot.com",
        "https://www.nme.com/gaming", "https://www.playstationlifestyle.net", "https://www.xbox.com", "https://www.nintendolife.com", "https://www.steampowered.com",
        "https://www.escapistmagazine.com", "https://www.twitch.tv", "https://www.reddit.com/r/games", "https://www.bungie.net", "https://www.blizzard.com",
        "https://www.ea.com", "https://www.ubisoft.com", "https://www.square-enix.com", "https://www.cdprojekt.com", "https://www.riotgames.com",
        "https://www.konami.com", "https://www.activision.com", "https://www.sony.com", "https://www.microsoft.com", "https://www.nintendo.com",
        "https://www.epicgames.com", "https://www.crytek.com", "https://www.valvesoftware.com", "https://www.bandainamcoent.com", "https://www.take2games.com",
        "https://www.paradoxinteractive.com", "https://www.505games.com", "https://www.kaiju-entertainment.com", "https://www.unrealengine.com", "https://www.teamspeak.com",
        "https://www.wargaming.net", "https://www.farmingsimulator.com", "https://www.scribblenauts.com", "https://www.leagueoflegends.com", "https://www.overwatchleague.com"
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Pesquise sites de jogos", text: $searchText)
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .padding([.leading, .trailing])
                
                List(filteredSites, id: \.self) { site in
                    HStack {
                        Text(site)
                            .lineLimit(1)
                        Spacer()
                        Button(action: {
                            if let url = URL(string: site) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "link")
                                .foregroundColor(.black)
                        }
                       Divider()
                    }
                    .padding()
                }
            }
            .navigationTitle("GSearch")
        }
    }
    
    var filteredSites: [String] {
        if searchText.isEmpty {
            return gamesSites
        } else {
            return gamesSites.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
}
