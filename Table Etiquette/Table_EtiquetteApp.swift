//
//  Table_EtiquetteApp.swift
//  Table Etiquette
//
//  Created by Bekhruzjon Hakmirzaev on 05/05/25.
//

import SwiftUI
import UserNotifications
import AVFoundation

@main
struct Table_EtiquetteApp: App {
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .onAppear {
                    configureApp()
                }
        }
    }
    
    private func configureApp() {
        // Configure notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Setup notification categories
        setupNotificationCategories()
        
        // Request permissions on first launch
        Task {
            await notificationManager.requestNotificationPermission()
            await requestCameraPermission()
        }
    }
    
    private func requestCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                print("Camera permission granted")
            } else {
                print("Camera permission denied")
            }
        case .denied, .restricted:
            print("Camera permission previously denied or restricted")
        case .authorized:
            print("Camera permission already granted")
        @unknown default:
            break
        }
    }
    
    private func setupNotificationCategories() {
        let viewTipAction = UNNotificationAction(
            identifier: "VIEW_TIP",
            title: "View Tip",
            options: [.foreground]
        )
        
        let practiceAction = UNNotificationAction(
            identifier: "PRACTICE_AR",
            title: "Practice with AR",
            options: [.foreground]
        )
        
        let dailyTipCategory = UNNotificationCategory(
            identifier: "DAILY_TIP",
            actions: [viewTipAction, practiceAction],
            intentIdentifiers: [],
            options: []
        )
        
        let readArticleAction = UNNotificationAction(
            identifier: "READ_ARTICLE",
            title: "Read Articles",
            options: [.foreground]
        )
        
        let weeklyArticleCategory = UNNotificationCategory(
            identifier: "WEEKLY_ARTICLE",
            actions: [readArticleAction, practiceAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            dailyTipCategory,
            weeklyArticleCategory
        ])
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        switch response.actionIdentifier {
        case "VIEW_TIP", "READ_ARTICLE":
            // Open app to articles section
            NotificationCenter.default.post(name: .openArticles, object: nil)
            
        case "PRACTICE_AR":
            // Open app to AR practice
            NotificationCenter.default.post(name: .openARPractice, object: nil)
            
        default:
            // Default tap - open app normally
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openArticles = Notification.Name("openArticles")
    static let openARPractice = Notification.Name("openARPractice")
}
