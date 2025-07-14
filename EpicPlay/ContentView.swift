//
//  ContentView.swift
//  EpicPlay
//
//  Created by Rodrigo Rochin on 14/07/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        WebView(url: URL(string: "https://studio--epic-play.us-central1.hosted.app/")!)
            .edgesIgnoringSafeArea(.all)
    }
}


#Preview {
    ContentView()
}
