//
//  ContentView.swift
//  Info_tabs
//
//  Created by Diego D’Angelo-Cosme on 4/17/25.
//

import SwiftUI

struct RightOfWayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Sailboat Right of Way Rules")
                .font(.title2)
                .bold()
                .padding(.top)

            RuleCard(title: "Port vs. Starboard", description: "When two sailboats are approaching, the boat on the port tack must give way to the boat on the starboard tack.")

            RuleCard(title: "Windward vs. Leeward", description: "When both boats are on the same tack, the windward boat must keep clear of the leeward boat.")

            RuleCard(title: "Overtaking", description: "Any vessel overtaking another must keep clear, regardless of whether it is under sail or motor.")

            RuleCard(title: "Power vs. Sail", description: "A sailboat under sail has right of way over powerboats, unless it’s overtaking.")

            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}

struct DockingProcedureView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Docking a Sailboat")
                .font(.title2)
                .bold()
                .padding(.top)

            RuleCard(title: "1. Get Ready", description: "Place fenders on the dock side. Have lines ready at the bow and stern.")

            RuleCard(title: "2. Approach Slowly", description: "Come in at a shallow angle (around 20°) and go slow — use small engine power or sail drift.")

            RuleCard(title: "3. Assign Quick Roles", description: "One person steers, another handles the lines. If solo, secure the bow line first.")

            RuleCard(title: "4. Secure the Boat", description: "Tie off the bow and stern lines. Use a spring line if needed to stop forward/backward motion.")

            RuleCard(title: "5. Shut Down", description: "Turn off the engine, tidy the deck, and make sure everything is safe and stowed.")

            Spacer()
        }
        .padding()
        
        .background(Color.white)
    }
}


struct RuleCard: View {
    var title: String
    var description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)

            Text(description)
                .font(.body)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct InfoTabViewPage: View {
    var body: some View {
        TabView {
            RightOfWayView()
                .tabItem {
                    Label("Right of Way", systemImage: "sailboat.fill")
                }

            DockingProcedureView()
                .tabItem {
                    Label("Docking", systemImage: "dock.rectangle")
                }
        }
    }
}

/*
struct ContentView: View {
    var body: some View {
        TabView {
            RightOfWayView()
                .tabItem {
                    Label("Right of Way", systemImage: "sailboat.fill")
                }

            DockingProcedureView()
                .tabItem {
                    Label("Docking", systemImage: "dock.rectangle")
                }
        }
    }
}
*/
