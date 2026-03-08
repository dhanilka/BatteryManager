//
//  BatteryViewModel.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import Foundation
import Combine
import SwiftUI

class BatteryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var batteryInfo: BatteryInfo?
    @Published var hasBattery: Bool = true
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    // History for graphing (last 60 data points = 3 minutes at 3-second intervals)
    @Published var batteryHistory: [BatteryHistoryPoint] = []
    
    // Alert Settings
    @Published var alertsEnabled: Bool = false
    @Published var highBatteryAlertEnabled: Bool = false
    @Published var lowBatteryAlertEnabled: Bool = true
    @Published var highBatteryThreshold: Int = 80
    @Published var lowBatteryThreshold: Int = 20
    
    // MARK: - Private Properties
    private let batteryService = BatteryService.shared
    private var timer: Timer?
    private let updateInterval: TimeInterval = 3.0 // 3 seconds
    private let maxHistoryPoints = 60
    
    // Track last alert states to prevent duplicate notifications
    private var lastHighAlertTriggered = false
    private var lastLowAlertTriggered = false
    
    // MARK: - Initialization
    init() {
        loadSettings()
        checkBatteryAvailability()
        startUpdating()
    }
    
    deinit {
        stopUpdating()
    }
    
    // MARK: - Public Methods
    
    func startUpdating() {
        // Initial fetch
        updateBatteryInfo()
        
        // Set up timer for regular updates
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateBatteryInfo()
        }
    }
    
    func stopUpdating() {
        timer?.invalidate()
        timer = nil
    }
    
    func refresh() {
        updateBatteryInfo()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(alertsEnabled, forKey: "alertsEnabled")
        UserDefaults.standard.set(highBatteryAlertEnabled, forKey: "highBatteryAlertEnabled")
        UserDefaults.standard.set(lowBatteryAlertEnabled, forKey: "lowBatteryAlertEnabled")
        UserDefaults.standard.set(highBatteryThreshold, forKey: "highBatteryThreshold")
        UserDefaults.standard.set(lowBatteryThreshold, forKey: "lowBatteryThreshold")
    }
    
    // MARK: - Private Methods
    
    private func checkBatteryAvailability() {
        hasBattery = batteryService.hasBattery()
        
        if !hasBattery {
            errorMessage = "No battery detected. This Mac may not have a battery."
            isLoading = false
        }
    }
    
    private func updateBatteryInfo() {
        guard hasBattery else { return }
        
        if let info = batteryService.getBatteryInfo() {
            DispatchQueue.main.async {
                self.batteryInfo = info
                self.isLoading = false
                self.errorMessage = nil
                
                // Add to history
                self.addToHistory(info)
                
                // Check for alerts
                self.checkAlerts(info)
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to retrieve battery information."
                self.isLoading = false
            }
        }
    }
    
    private func addToHistory(_ info: BatteryInfo) {
        let point = BatteryHistoryPoint(
            timestamp: Date(),
            percentage: info.percentage,
            watts: info.watts,
            isCharging: info.isCharging
        )
        
        batteryHistory.append(point)
        
        // Keep only the last maxHistoryPoints
        if batteryHistory.count > maxHistoryPoints {
            batteryHistory.removeFirst(batteryHistory.count - maxHistoryPoints)
        }
    }
    
    private func loadSettings() {
        alertsEnabled = UserDefaults.standard.bool(forKey: "alertsEnabled")
        highBatteryAlertEnabled = UserDefaults.standard.bool(forKey: "highBatteryAlertEnabled")
        lowBatteryAlertEnabled = UserDefaults.standard.object(forKey: "lowBatteryAlertEnabled") as? Bool ?? true
        highBatteryThreshold = UserDefaults.standard.object(forKey: "highBatteryThreshold") as? Int ?? 80
        lowBatteryThreshold = UserDefaults.standard.object(forKey: "lowBatteryThreshold") as? Int ?? 20
    }
    
    private func checkAlerts(_ info: BatteryInfo) {
        guard alertsEnabled else { return }
        
        // High battery alert (only when charging)
        if highBatteryAlertEnabled && info.isCharging && info.percentage >= highBatteryThreshold && !lastHighAlertTriggered {
            NotificationCenter.default.post(
                name: .batteryHighAlert,
                object: nil,
                userInfo: ["percentage": info.percentage]
            )
            lastHighAlertTriggered = true
        } else if info.percentage < highBatteryThreshold {
            lastHighAlertTriggered = false
        }
        
        // Low battery alert (only when discharging)
        if lowBatteryAlertEnabled && !info.isCharging && info.percentage <= lowBatteryThreshold && !lastLowAlertTriggered {
            NotificationCenter.default.post(
                name: .batteryLowAlert,
                object: nil,
                userInfo: ["percentage": info.percentage]
            )
            lastLowAlertTriggered = true
        } else if info.percentage > lowBatteryThreshold {
            lastLowAlertTriggered = false
        }
    }
}

// MARK: - Battery History Point

struct BatteryHistoryPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let percentage: Int
    let watts: Double
    let isCharging: Bool
}

// MARK: - Notification Names

extension Notification.Name {
    static let batteryHighAlert = Notification.Name("batteryHighAlert")
    static let batteryLowAlert = Notification.Name("batteryLowAlert")
}
