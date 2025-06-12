//
//  NotificationManager.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import Foundation
import UserNotifications
import SwiftUI

// MARK: - Table Manners Article Model
struct TableMannersArticle: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let category: ArticleCategory
    let date: Date
    let readingTime: String
    let imageURL: String?
    let sourceURL: String?
    
    enum ArticleCategory: String, CaseIterable, Codable {
        case basic = "Basic Etiquette"
        case formal = "Formal Dining"
        case international = "International Customs"
        case business = "Business Dining"
        case tips = "Daily Tips"
        
        var icon: String {
            switch self {
            case .basic: return "house.fill"
            case .formal: return "crown.fill"
            case .international: return "globe.americas.fill"
            case .business: return "briefcase.fill"
            case .tips: return "lightbulb.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .basic: return .blue
            case .formal: return .purple
            case .international: return .green
            case .business: return .orange
            case .tips: return .yellow
            }
        }
    }
}

// MARK: - Daily Tip Model
struct DailyTip: Identifiable, Codable {
    let id = UUID()
    let tip: String
    let category: String
    let difficulty: TipDifficulty
    let emoji: String
    
    enum TipDifficulty: String, CaseIterable, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }
}

// MARK: - Notification Manager
@MainActor
class NotificationManager: ObservableObject {
    @Published var articles: [TableMannersArticle] = []
    @Published var dailyTip: DailyTip?
    @Published var hasPermission = false
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let dailyTipKey = "dailyTip"
    private let lastTipDateKey = "lastTipDate"
    
    init() {
        checkNotificationPermission()
        loadDailyTip()
        loadSampleArticles()
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() async {
        do {
            let permission = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            hasPermission = permission
            
            if permission {
                await scheduleDailyNotifications()
            }
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Daily Tips Management
    func loadDailyTip() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastTipDate = userDefaults.object(forKey: lastTipDateKey) as? Date,
           Calendar.current.isDate(lastTipDate, inSameDayAs: today),
           let tipData = userDefaults.data(forKey: dailyTipKey),
           let tip = try? JSONDecoder().decode(DailyTip.self, from: tipData) {
            dailyTip = tip
        } else {
            generateNewDailyTip()
        }
    }
    
    private func generateNewDailyTip() {
        let tips = TableMannersData.dailyTips
        if let randomTip = tips.randomElement() {
            dailyTip = randomTip
            saveDailyTip(randomTip)
        }
    }
    
    private func saveDailyTip(_ tip: DailyTip) {
        if let encoded = try? JSONEncoder().encode(tip) {
            userDefaults.set(encoded, forKey: dailyTipKey)
            userDefaults.set(Date(), forKey: lastTipDateKey)
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleDailyNotifications() async {
        guard hasPermission else { return }
        
        // Cancel existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule daily tip notifications
        await scheduleDailyTipNotifications()
        
        // Schedule weekly article notifications
        await scheduleWeeklyArticleNotifications()
    }
    
    private func scheduleDailyTipNotifications() async {
        let content = UNMutableNotificationContent()
        content.title = "Daily Table Etiquette Tip"
        content.body = "Learn something new about table manners today!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_TIP"
        
        // Schedule for 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_tip", content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleWeeklyArticleNotifications() async {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Table Manners Articles"
        content.body = "Discover new articles about international dining customs and etiquette!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_ARTICLE"
        
        // Schedule for Monday 7 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_article", content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Articles Management
    private func loadSampleArticles() {
        articles = TableMannersData.sampleArticles
    }
    
    func fetchArticles() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call - in real app, this would fetch from a real API
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // For now, load local sample data
        articles = TableMannersData.sampleArticles.shuffled()
    }
    
    func articlesFor(category: TableMannersArticle.ArticleCategory) -> [TableMannersArticle] {
        return articles.filter { $0.category == category }
    }
}

// MARK: - Table Manners Data
struct TableMannersData {
    static let dailyTips: [DailyTip] = [
        DailyTip(
            tip: "Always place your napkin on your lap as soon as you sit down.",
            category: "Basic Etiquette",
            difficulty: .beginner,
            emoji: "🍽️"
        ),
        DailyTip(
            tip: "When finished eating, place your knife and fork parallel on your plate at 4 o'clock position.",
            category: "Basic Etiquette",
            difficulty: .intermediate,
            emoji: "🍴"
        ),
        DailyTip(
            tip: "In formal dining, bread should be broken by hand, never cut with a knife.",
            category: "Formal Dining",
            difficulty: .advanced,
            emoji: "🍞"
        ),
        DailyTip(
            tip: "Wait for the host to begin eating before you start your meal.",
            category: "Basic Etiquette",
            difficulty: .beginner,
            emoji: "⏱️"
        ),
        DailyTip(
            tip: "Use utensils from outside to inside throughout the meal courses.",
            category: "Formal Dining",
            difficulty: .intermediate,
            emoji: "🥄"
        ),
        DailyTip(
            tip: "In Asian cultures, it's polite to slurp noodles to show appreciation.",
            category: "International",
            difficulty: .advanced,
            emoji: "🍜"
        ),
        DailyTip(
            tip: "Keep your phone on silent and avoid using it during meals.",
            category: "Modern Etiquette",
            difficulty: .beginner,
            emoji: "📱"
        ),
        DailyTip(
            tip: "Pass dishes to the right and always pass salt and pepper together.",
            category: "Basic Etiquette",
            difficulty: .beginner,
            emoji: "🧂"
        ),
        DailyTip(
            tip: "In France, keep your hands visible on the table, not in your lap.",
            category: "International",
            difficulty: .intermediate,
            emoji: "🇫🇷"
        ),
        DailyTip(
            tip: "Business dinners require impeccable etiquette as they reflect professionalism.",
            category: "Business Dining",
            difficulty: .advanced,
            emoji: "💼"
        )
    ]
    
    static let sampleArticles: [TableMannersArticle] = [
        TableMannersArticle(
            title: "The Complete Guide to Basic Table Manners",
            content: """
            Table manners are the foundation of proper dining etiquette. Whether you're eating at home, in a restaurant, or at a formal dinner, understanding basic table manners will help you feel confident and make a good impression.
            
            Essential Basic Rules:
            1. Wait for everyone to be served before eating
            2. Use utensils properly - fork in left hand, knife in right
            3. Chew with your mouth closed and don't talk with food in your mouth
            4. Keep your phone away from the table
            5. Say please and thank you regularly
            
            These fundamentals will serve you well in any dining situation and are the building blocks for more advanced etiquette skills.
            """,
            category: .basic,
            date: Date().addingTimeInterval(-86400), // Yesterday
            readingTime: "5 min read",
            imageURL: nil,
            sourceURL: "https://www.emilypost.com/advice/table-manners-101"
        ),
        
        TableMannersArticle(
            title: "Mastering Formal Dining: A Step-by-Step Guide",
            content: """
            Formal dining can seem intimidating, but with the right knowledge, you can navigate even the most elaborate table setting with confidence.
            
            Key Formal Dining Elements:
            • Multiple courses require different utensils
            • Work from outside utensils inward with each course
            • Bread plate is always to your left
            • Glasses are arranged above the plate
            • Wait for the host to begin each course
            
            Remember, formal dining is about respect for tradition and your fellow diners. Take your time, observe others, and don't be afraid to ask if you're unsure about something.
            """,
            category: .formal,
            date: Date().addingTimeInterval(-172800), // 2 days ago
            readingTime: "8 min read",
            imageURL: nil,
            sourceURL: "https://www.finedininglovers.com/article/formal-dining-etiquette"
        ),
        
        TableMannersArticle(
            title: "International Dining Customs: What You Need to Know",
            content: """
            Dining customs vary greatly around the world. What's considered polite in one culture might be rude in another. Here's a guide to international dining etiquette.
            
            Cultural Highlights:
            • Japan: Slurping noodles shows appreciation
            • France: Keep hands visible on the table
            • China: Leave a little food on your plate to show satisfaction
            • India: Eat with your right hand only
            • Middle East: Accept food offerings graciously
            
            When traveling or dining with people from other cultures, observing and asking questions shows respect and interest in their traditions.
            """,
            category: .international,
            date: Date().addingTimeInterval(-259200), // 3 days ago
            readingTime: "6 min read",
            imageURL: nil,
            sourceURL: "https://www.worldatlas.com/articles/dining-etiquette-around-the-world.html"
        ),
        
        TableMannersArticle(
            title: "Business Dining: Making the Right Impression",
            content: """
            Business meals are crucial opportunities to build relationships and demonstrate professionalism. Your table manners can significantly impact business outcomes.
            
            Business Dining Success Tips:
            1. Arrive on time and dress appropriately
            2. Let your host order first or ask for recommendations
            3. Keep business talk light until after ordering
            4. Order something easy to eat - avoid messy foods
            5. Follow your host's lead on alcohol
            
            Remember, the meal is secondary to the relationship building. Focus on making genuine connections while demonstrating your professional standards.
            """,
            category: .business,
            date: Date().addingTimeInterval(-345600), // 4 days ago
            readingTime: "7 min read",
            imageURL: nil,
            sourceURL: "https://www.businessinsider.com/business-dining-etiquette-rules"
        ),
        
        TableMannersArticle(
            title: "Quick Table Etiquette Tips for Everyday Dining",
            content: """
            Good table manners don't just apply to formal occasions. Practicing proper etiquette in everyday situations helps make good habits automatic.
            
            Daily Practice Tips:
            • Use your napkin properly - unfold, place on lap, dab don't wipe
            • Pass items clockwise around the table
            • Ask "please pass" instead of reaching across
            • Compliment the cook or meal
            • Offer to help clear the table
            
            Small gestures of courtesy make every meal more enjoyable for everyone involved and help you maintain good habits for special occasions.
            """,
            category: .tips,
            date: Date().addingTimeInterval(-432000), // 5 days ago
            readingTime: "3 min read",
            imageURL: nil,
            sourceURL: "https://www.thespruceeats.com/table-manners-and-etiquette-1216920"
        )
    ]
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var selectedCategory: TableMannersArticle.ArticleCategory = .basic
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Permission Section
                permissionSection
                
                // Daily Tip Section
                dailyTipSection
                
                // Articles Section
                articlesSection
            }
            .padding()
        }
        .navigationTitle("Table Manners Hub")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.accentColor.opacity(0.08)
            .ignoresSafeArea())
        .refreshable {
            await notificationManager.fetchArticles()
        }
        .task {
            await notificationManager.fetchArticles()
        }
    }
    
    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Tips & Articles")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Get daily etiquette tips and weekly articles")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if notificationManager.hasPermission {
                    Label("Enabled", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Button("Enable") {
                        Task {
                            await notificationManager.requestNotificationPermission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
        }
    }
    
    private var dailyTipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Tip")
                .font(.headline)
                .fontWeight(.bold)
            
            if let tip = notificationManager.dailyTip {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(tip.emoji)
                            .font(.title)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tip.category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Label(tip.difficulty.rawValue, systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(tip.difficulty.color)
                        }
                        
                        Spacer()
                    }
                    
                    Text(tip.tip)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .shadow(radius: 2)
                )
            }
        }
    }
    
    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Articles & Guides")
                .font(.headline)
                .fontWeight(.bold)
            
            // Category Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TableMannersArticle.ArticleCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedCategory == category ? category.color : Color(.systemGray5))
                            )
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Articles List
            LazyVStack(spacing: 12) {
                ForEach(notificationManager.articlesFor(category: selectedCategory)) { article in
                    ArticleRowView(article: article)
                }
            }
            
            if notificationManager.isLoading {
                ProgressView("Loading articles...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
}

// MARK: - Article Row View
struct ArticleRowView: View {
    let article: TableMannersArticle
    @State private var showingArticle = false
    
    var body: some View {
        Button(action: { showingArticle = true }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                        
                        Text(article.readingTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: article.category.icon)
                        .font(.title2)
                        .foregroundColor(article.category.color)
                }
                
                Text(article.content.prefix(100) + "...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingArticle) {
            ArticleDetailView(article: article)
        }
    }
}

// MARK: - Article Detail View
struct ArticleDetailView: View {
    let article: TableMannersArticle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(article.category.rawValue, systemImage: article.category.icon)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(article.category.color)
                            
                            Spacer()
                            
                            Text(article.readingTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(article.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Divider()
                    
                    // Content
                    Text(article.content)
                        .font(.body)
                        .lineSpacing(4)
                    
                    if let sourceURL = article.sourceURL {
                        Link("Read Full Article", destination: URL(string: sourceURL)!)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
