//
//  AlertManager.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import Foundation
import UserNotifications

class AlertManager: NSObject {
    static let shared = AlertManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var hasRequestedPermission = false
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationObservers()
    }
    
    // MARK: - Setup
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBatteryHighAlert(_:)),
            name: .batteryHighAlert,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBatteryLowAlert(_:)),
            name: .batteryLowAlert,
            object: nil
        )
    }
    
    // MARK: - Permission
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        // First check current status
        notificationCenter.getNotificationSettings { settings in
            // If already authorized, no need to request again
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    self.hasRequestedPermission = true
                    completion(true)
                }
                return
            }
            
            // If denied, inform user they need to enable in System Settings
            if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    self.hasRequestedPermission = true
                    print("⚠️ Notifications are disabled. Enable them in System Settings > Notifications > Battery Manager")
                    completion(false)
                }
                return
            }
            
            // Request authorization
            self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    self.hasRequestedPermission = true
                    if let error = error {
                        print("❌ Error requesting notification permission: \(error.localizedDescription)")
                        print("💡 This usually means:")
                        print("   1. App needs to be properly code-signed")
                        print("   2. Entitlements file needs to be added to the project")
                        print("   3. Or disable App Sandbox in project settings")
                        completion(false)
                    } else {
                        if granted {
                            print("✅ Notification permission granted")
                        } else {
                            print("⚠️ Notification permission denied by user")
                        }
                        completion(granted)
                    }
                }
            }
        }
    }
    
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Alert Handlers
    
    @objc private func handleBatteryHighAlert(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let percentage = userInfo["percentage"] as? Int else {
            return
        }
        
        sendNotification(
            title: "Battery Charged",
            body: "Your battery is now at \(percentage)%. Consider unplugging to preserve battery health.",
            identifier: "battery.high",
            sound: .default
        )
    }
    
    @objc private func handleBatteryLowAlert(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let percentage = userInfo["percentage"] as? Int else {
            return
        }
        
        sendNotification(
            title: "Low Battery",
            body: "Your battery is at \(percentage)%. Please connect your power adapter.",
            identifier: "battery.low",
            sound: .default
        )
    }
    
    // MARK: - Send Notification
    
    private func sendNotification(
        title: String,
        body: String,
        identifier: String,
        sound: UNNotificationSound
    ) {
        // Check if we have permission first
        checkPermissionStatus { [weak self] hasPermission in
            guard hasPermission else {
                print("No notification permission granted")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = sound
            content.categoryIdentifier = "battery.alert"
            
            // Create request with unique identifier to replace previous notifications
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil // Deliver immediately
            )
            
            self?.notificationCenter.add(request) { error in
                if let error = error {
                    print("Error sending notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Clear Notifications
    
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func clearNotification(withIdentifier identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AlertManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap if needed
        // For example, open the dashboard window
        
        switch response.notification.request.identifier {
        case "battery.high", "battery.low":
            // Could open the dashboard window here
            // NSApp.sendAction(#selector(NSApplication.activateIgnoringOtherApps(_:)), to: nil, from: true)
            break
        default:
            break
        }
        
        completionHandler()
    }
}
