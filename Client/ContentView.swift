//
//  ContentView.swift
//  Client
//
//  Created by Денис Юрієвич on 13.07.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "hryvniasign.square.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Swaga Ukrainian Client!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
