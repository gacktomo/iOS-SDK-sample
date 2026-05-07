//
//  ContentView.swift
//  demo
//

import SwiftUI
import ParentSDK

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Demo App")
                .font(.title)
            ParentButton()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
