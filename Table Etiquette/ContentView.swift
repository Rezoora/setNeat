//
//  ContentView.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import SwiftUI

struct ContentView: View {
    @State private var searchStyle: String = ""
    @State private var selectedFoodTime: FoodTime? = nil
    @State private var selectedTableDesign: TableDesign? = nil
    @State private var selection: Selection? = nil
    
    let poloBlue = Color(red: 147/255, green: 173/255, blue: 203/255)
    
    let foodTimes: [FoodTime] = [.breakfast, .lunch, .dinner]
    let tableDesigns: [TableDesign] = [.basic, .casual, .formal]
    
    var filteredDesigns: [TableDesign] {
        if searchStyle.isEmpty { return tableDesigns }
        return tableDesigns.filter { $0.rawValue.localizedCaseInsensitiveContains(searchStyle) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.accentColor.opacity(0.08)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        // Title
                        Text("Table Design")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        // Articles button
                        NavigationLink(destination: NotificationSettingsView()) {
                            Image(systemName: "book.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.blue)
                                .scaledToFit()
                        }
                        .padding(.trailing, 8)
                        
//                        Button(action: {}) {
//                            Image("plus.button")
//                                .resizable()
//                                .frame(width: 25, height: 25)
//                                .scaledToFit()
//                        }.padding(.trailing)
                        
                    }.padding(.horizontal, 5)
                    
                    Divider()
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search Design", text: $searchStyle)
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .background(poloBlue.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    // Food Time Selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack {
                            
                            HStack {}
                                .frame(maxWidth: .infinity, maxHeight: 1)
                                .background(Color.gray.opacity(0.8))
                                .padding(.bottom)
                                .padding(.horizontal).padding(.horizontal)
                                .padding(.trailing).padding(.trailing).padding(.trailing)
                            
                            HStack(spacing: 43) {
                                ForEach(foodTimes, id: \ .self) { time in
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedFoodTime == time ? poloBlue.opacity(0.8) : Color.white)
                                                .frame(width: 51, height: 51)
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedFoodTime == time ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                                                )
                                            Image(time.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                        }
                                        Text(time.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    .onTapGesture {
                                        if selectedFoodTime == time {
                                            selectedFoodTime = nil
                                        } else {
                                            selectedFoodTime = time
                                        }
                                        tryNavigate()
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 4)
                        }
                    }
                    
                    // Table Design Selection
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(filteredDesigns, id: \ .self) { design in
                                Button(action: {
                                    if selectedTableDesign == design {
                                        selectedTableDesign = nil
                                    } else {
                                        selectedTableDesign = design
                                    }
                                    tryNavigate()
                                }) {
                                    ZStack(alignment: .bottomLeading) {
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(poloBlue.opacity(0.8))
                                            .frame(height: 160)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 30)
                                                    .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                                                    .foregroundColor(Color.gray.opacity(0.5))
                                            )
                                        
                                        HStack {
                                            Spacer()
                                            Image(design.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 150)
                                                .clipped()
                                                .cornerRadius(30)
                                                .opacity(0.95)
                                            Spacer()
                                        }
                                        Text(design.rawValue)
                                            .foregroundColor(.primary)
                                            .font(.system(size: 33, weight: .medium))
                                            .padding([.leading, .bottom], 20)
                                            .shadow(radius: 3)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(selectedTableDesign == design ? Color.accentColor : Color.clear, lineWidth: 4)
                                    )
                                }
                            }
                        }
                        .padding(.top, 5)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }.padding(.top)
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selection) { selection in
                FoodTypeView(foodTime: selection.foodTime, tableDesign: selection.tableDesign)
            }
        }
    }
    
    private func tryNavigate() {
        if let food = selectedFoodTime, let design = selectedTableDesign {
            selection = Selection(foodTime: food, tableDesign: design)
        } else {
            selection = nil
        }
    }
}

// MARK: - Supporting Types

enum FoodTime: String, CaseIterable, Hashable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    
    var title: String { rawValue }
    var imageName: String {
        switch self {
        case .breakfast: return "breakfast"
        case .lunch: return "lunch"
        case .dinner: return "dinner"
        }
    }
}

enum TableDesign: String, CaseIterable, Hashable {
    case basic = "Basic"
    case casual = "Casual"
    case formal = "Formal"
    
    var imageName: String {
        switch self {
        case .basic: return "basic"
        case .casual: return "casual"
        case .formal: return "formal"
        }
    }
}

struct Selection: Identifiable, Hashable {
    let id = UUID()
    let foodTime: FoodTime
    let tableDesign: TableDesign
}

#Preview {
    ContentView()
}
