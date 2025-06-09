//
//  TableEtiquetteWidget.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Configuration
struct TableEtiquetteWidget: Widget {
    let kind: String = "TableEtiquetteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TableEtiquetteProvider()) { entry in
            TableEtiquetteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Table Etiquette Daily")
        .description("Daily tips and insights about proper table manners and dining etiquette.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider
struct TableEtiquetteProvider: TimelineProvider {
    func placeholder(in context: Context) -> TableEtiquetteEntry {
        TableEtiquetteEntry(
            date: Date(),
            tip: DailyTip(
                tip: "Always place your napkin on your lap when seated.",
                category: "Basic Etiquette",
                difficulty: .beginner,
                emoji: "🍽️"
            ),
            quote: "Good manners are a passport that will take you anywhere.",
            isPlaceholder: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TableEtiquetteEntry) -> ()) {
        let entry = TableEtiquetteEntry(
            date: Date(),
            tip: TableMannersData.dailyTips.randomElement()!,
            quote: DiningQuotes.randomQuote(),
            isPlaceholder: false
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TableEtiquetteEntry>) -> ()) {
        let currentDate = Date()
        let midnight = Calendar.current.startOfDay(for: currentDate)
        let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: midnight)!
        
        // Create entry for today
        let todayTip = getTodaysTip()
        let entry = TableEtiquetteEntry(
            date: currentDate,
            tip: todayTip,
            quote: DiningQuotes.randomQuote(),
            isPlaceholder: false
        )
        
        // Update at midnight each day
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
    
    private func getTodaysTip() -> DailyTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let tipIndex = (dayOfYear - 1) % TableMannersData.dailyTips.count
        return TableMannersData.dailyTips[tipIndex]
    }
}

// MARK: - Widget Entry
struct TableEtiquetteEntry: TimelineEntry {
    let date: Date
    let tip: DailyTip
    let quote: String
    let isPlaceholder: Bool
}

// MARK: - Widget View
struct TableEtiquetteWidgetEntryView: View {
    var entry: TableEtiquetteProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: TableEtiquetteEntry
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.8),
                    Color.accentColor.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // Animated emoji
                Text(entry.tip.emoji)
                    .font(.system(size: 32))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Difficulty indicator
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < difficultyLevel ? entry.tip.difficulty.color : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Category
                Text(entry.tip.category)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                
                // Tip preview
                Text(entry.tip.tip)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var difficultyLevel: Int {
        switch entry.tip.difficulty {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: TableEtiquetteEntry
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background with pattern
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.8),
                    Color.accentColor.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative pattern
            VStack {
                HStack {
                    Spacer()
                    ForEach(0..<3) { _ in
                        Image(systemName: "fork.knife")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.1))
                            .rotationEffect(.degrees(45))
                    }
                }
                Spacer()
            }
            .padding()
            
            HStack(spacing: 16) {
                // Left side - emoji and indicators
                VStack(spacing: 12) {
                    Text(entry.tip.emoji)
                        .font(.system(size: 48))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Difficulty stars
                    HStack(spacing: 3) {
                        ForEach(0..<3) { index in
                            Image(systemName: index < difficultyLevel ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(entry.tip.difficulty.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Right side - content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Tip")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(entry.tip.category)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(entry.tip.tip)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // App link hint
                    HStack {
                        Image(systemName: "arkit")
                            .font(.caption)
                        Text("Practice with AR")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var difficultyLevel: Int {
        switch entry.tip.difficulty {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: TableEtiquetteEntry
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.9),
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated background elements
            VStack {
                HStack {
                    ForEach(0..<4) { i in
                        Image(systemName: "fork.knife")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.1))
                            .rotationEffect(.degrees(rotationAngle + Double(i * 90)))
                            .animation(
                                Animation.linear(duration: 20).repeatForever(autoreverses: false),
                                value: rotationAngle
                            )
                        Spacer()
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    ForEach(0..<3) { i in
                        Image(systemName: "wineglass")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.08))
                            .rotationEffect(.degrees(-rotationAngle + Double(i * 120)))
                        Spacer()
                    }
                }
            }
            .padding()
            
            VStack(spacing: 20) {
                // Header section
                VStack(spacing: 12) {
                    Text("Table Etiquette Daily")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(entry.tip.emoji)
                            .font(.system(size: 60))
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.tip.category)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack {
                                ForEach(0..<3) { index in
                                    Image(systemName: index < difficultyLevel ? "star.fill" : "star")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                }
                                Text(entry.tip.difficulty.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Main tip section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Etiquette Tip")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(entry.tip.tip)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                
                // Quote section
                VStack(spacing: 8) {
                    Text("Dining Wisdom")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\"\(entry.quote)\"")
                        .font(.callout)
                        .italic()
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Action hint
                HStack {
                    Image(systemName: "arkit")
                        .font(.headline)
                    Text("Open app to practice with AR")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.headline)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.2))
                )
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
    
    private var difficultyLevel: Int {
        switch entry.tip.difficulty {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

// MARK: - Dining Quotes
struct DiningQuotes {
    static let quotes = [
        "Good manners are a passport that will take you anywhere.",
        "Etiquette is the art of making other people comfortable.",
        "Table manners are not rocket science, but they are civilizing.",
        "Courtesy is a small act but it packs a mighty wallop.",
        "Manners are a sensitive awareness of the feelings of others.",
        "The way you eat reflects the way you live.",
        "Dining is an art form when done with proper etiquette.",
        "Good table manners are invisible until they're missing.",
        "Etiquette is about putting others at ease and feeling comfortable.",
        "A well-set table is a canvas for memorable dining experiences."
    ]
    
    static func randomQuote() -> String {
        return quotes.randomElement() ?? quotes[0]
    }
}

// MARK: - Widget Bundle
struct TableEtiquetteWidgetBundle: WidgetBundle {
    var body: some Widget {
        TableEtiquetteWidget()
    }
}

// MARK: - Preview
struct TableEtiquetteWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TableEtiquetteWidgetEntryView(entry: TableEtiquetteEntry(
                date: Date(),
                tip: DailyTip(
                    tip: "Always place your napkin on your lap as soon as you sit down.",
                    category: "Basic Etiquette",
                    difficulty: .beginner,
                    emoji: "🍽️"
                ),
                quote: "Good manners are a passport that will take you anywhere.",
                isPlaceholder: false
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small Widget")
            
            TableEtiquetteWidgetEntryView(entry: TableEtiquetteEntry(
                date: Date(),
                tip: DailyTip(
                    tip: "Use utensils from outside to inside throughout the meal courses.",
                    category: "Formal Dining",
                    difficulty: .intermediate,
                    emoji: "🥄"
                ),
                quote: "Etiquette is the art of making other people comfortable.",
                isPlaceholder: false
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium Widget")
            
            TableEtiquetteWidgetEntryView(entry: TableEtiquetteEntry(
                date: Date(),
                tip: DailyTip(
                    tip: "In formal dining, bread should be broken by hand, never cut with a knife.",
                    category: "Advanced Techniques",
                    difficulty: .advanced,
                    emoji: "🍞"
                ),
                quote: "Table manners are not rocket science, but they are civilizing.",
                isPlaceholder: false
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large Widget")
        }
    }
} 