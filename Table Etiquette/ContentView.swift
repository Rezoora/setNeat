//
//  ContentView.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import SwiftUI

struct ContentView: View {
    @State var searchStyle: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                NavigationLink(destination: BasicTabelView(), label: {
                    ZStack(alignment: .bottomLeading) {
                        Image("basic")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                        Rectangle().fill(LinearGradient(colors: [.clear, .accentColor.opacity(0.3)], startPoint: .trailing, endPoint: .leading))
                        VStack(alignment: .leading) {
                            Text("Basic")
                                .foregroundStyle(.white)
                                .font(.title).bold()
                        }.padding()
                    }.cornerRadius(30)
                })
            }.padding()
            .navigationTitle("Table Etiquette")
            .searchable(text: $searchStyle)
        }
    }
}

#Preview {
    ContentView()
}
