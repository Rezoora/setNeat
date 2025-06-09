import SwiftUI

struct FoodTypeView: View {
    let foodTime: FoodTime
    let tableDesign: TableDesign
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFoodType: FoodType? = nil
    @State private var showTableView: Bool = false
    
    let foodTypes: [FoodType] = [.international, .italian, .asian, .middleEastern, .indian]
    
    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.08).ignoresSafeArea()
            VStack(spacing: 0) {
                // Title bar
                HStack(alignment: .center) {
                    Image(foodTime.imageName)
                        .resizable()
                        .frame(width: 44, height: 44)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                    Text(tableDesign.rawValue)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    // Articles button
                    NavigationLink(destination: NotificationSettingsView()) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.blue.gradient)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color.accentColor.opacity(0.5))
                    }
                }
                .padding([.horizontal, .top])
                Divider().padding(.bottom, 8)
                // Food type cards
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(foodTypes, id: \.self) { type in
                            Button(action: {
                                if selectedFoodType == type {
                                    selectedFoodType = nil
                                } else {
                                    selectedFoodType = type
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 40)
                                        .fill(Color.accentColor.opacity(0.25))
                                        .frame(height: 80)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 40)
                                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                                .foregroundColor(Color.gray.opacity(0.3))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 40)
                                                .stroke(selectedFoodType == type ? Color.accentColor : Color.clear, lineWidth: 4)
                                        )
                                    if selectedFoodType == type {
                                        // Pattern overlay for selected
                                        HStack(spacing: 0) {
                                            ForEach(0..<8) { _ in
                                                Image(systemName: "fork.knife")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 32, height: 32)
                                                    .opacity(0.15)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    Text(type.title)
                                        .font(.system(size: 32, weight: .bold))
                                        
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                Spacer()
                // AR Button
                Button(action: { showTableView = true }) {
                    HStack {
                        Text("AR")
                            .font(.system(size: 32, weight: .bold))
                        Image(systemName: "arkit")
                            .font(.system(size: 28, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .background(Color.accentColor)
                    .cornerRadius(35)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
                .fullScreenCover(isPresented: $showTableView) {
                    switch tableDesign {
                    case .basic:
                        BasicTableView()
                    case .casual:
                        CasualTableView()
                    case .formal:
                        FormalTableView()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

// MARK: - FoodType Enum

enum FoodType: String, CaseIterable, Hashable {
    case international = "International"
    case italian = "Italian"
    case asian = "Asian"
    case middleEastern = "Middle Eastern"
    case indian = "Indian"
    
    var title: String { rawValue }
}

#Preview {
    FoodTypeView(foodTime: .breakfast, tableDesign: .casual)
} 
