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
    @Published var customLevelAlertsEnabled: Bool = false
    @Published var customAlertLevelsInput: String = "15,30,50,80"
    @Published var criticalBatteryAlertEnabled: Bool = false
    @Published var criticalBatteryThreshold: Int = 5
    
    // MARK: - Private Properties
    private let batteryService = BatteryService.shared
    private var timer: Timer?
    private let updateInterval: TimeInterval = 3.0 // 3 seconds
    private let maxHistoryPoints = 60
    
    // Track last alert states to prevent duplicate notifications
    private var lastHighAlertTriggered = false
    private var lastLowAlertTriggered = false
    private var lastCriticalAlertTriggered = false
    private var lastKnownPercentage: Int?
    
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
        UserDefaults.standard.set(customLevelAlertsEnabled, forKey: "customLevelAlertsEnabled")
        UserDefaults.standard.set(sanitizedCustomAlertLevelsString(), forKey: "customAlertLevelsInput")
        UserDefaults.standard.set(criticalBatteryAlertEnabled, forKey: "criticalBatteryAlertEnabled")
        UserDefaults.standard.set(criticalBatteryThreshold, forKey: "criticalBatteryThreshold")
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
        customLevelAlertsEnabled = UserDefaults.standard.bool(forKey: "customLevelAlertsEnabled")
        customAlertLevelsInput = UserDefaults.standard.string(forKey: "customAlertLevelsInput") ?? "15,30,50,80"
        criticalBatteryAlertEnabled = UserDefaults.standard.bool(forKey: "criticalBatteryAlertEnabled")
        criticalBatteryThreshold = UserDefaults.standard.object(forKey: "criticalBatteryThreshold") as? Int ?? 5
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

        checkCustomLevelAlerts(info)
        checkCriticalBatteryAlert(info)

        lastKnownPercentage = info.percentage
    }

    private func checkCustomLevelAlerts(_ info: BatteryInfo) {
        guard customLevelAlertsEnabled else { return }
        let levels = parsedCustomAlertLevels()
        guard !levels.isEmpty else { return }
        guard let previousPercentage = lastKnownPercentage else { return }

        for level in levels {
            let crossedUp = previousPercentage < level && info.percentage >= level
            let crossedDown = previousPercentage > level && info.percentage <= level
            guard crossedUp || crossedDown else { continue }

            NotificationCenter.default.post(
                name: .batteryCustomLevelAlert,
                object: nil,
                userInfo: [
                    "percentage": info.percentage,
                    "targetLevel": level,
                    "direction": crossedUp ? "up" : "down"
                ]
            )
        }
    }

    private func checkCriticalBatteryAlert(_ info: BatteryInfo) {
        guard criticalBatteryAlertEnabled else { return }

        if !info.isCharging && info.percentage <= criticalBatteryThreshold && !lastCriticalAlertTriggered {
            NotificationCenter.default.post(
                name: .batteryCriticalAlert,
                object: nil,
                userInfo: [
                    "percentage": info.percentage,
                    "threshold": criticalBatteryThreshold
                ]
            )
            lastCriticalAlertTriggered = true
        } else if info.percentage > criticalBatteryThreshold {
            lastCriticalAlertTriggered = false
        }
    }

    private func parsedCustomAlertLevels() -> [Int] {
        let levels = customAlertLevelsInput
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { (1...99).contains($0) }

        return Array(Set(levels)).sorted()
    }

    private func sanitizedCustomAlertLevelsString() -> String {
        let levels = parsedCustomAlertLevels()
        let normalized = levels.map(String.init).joined(separator: ",")
        customAlertLevelsInput = normalized.isEmpty ? "15,30,50,80" : normalized
        return customAlertLevelsInput
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
    static let batteryCustomLevelAlert = Notification.Name("batteryCustomLevelAlert")
    static let batteryCriticalAlert = Notification.Name("batteryCriticalAlert")
}
