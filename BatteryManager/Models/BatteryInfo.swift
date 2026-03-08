//
//  BatteryInfo.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import Foundation

struct BatteryInfo {
    // Basic Information
    let percentage: Int
    let isCharging: Bool
    let isPluggedIn: Bool
    let timeRemaining: Int? // Minutes, nil if calculating
    
    // Health Metrics
    let health: Int // Percentage
    let cycleCount: Int
    let condition: String // "Normal", "Replace Soon", "Replace Now", "Service Battery"
    
    // Electrical Properties
    let voltage: Double // Volts
    let amperage: Double // Amperes (negative when discharging)
    let watts: Double // Watts (calculated from voltage * amperage)
    
    // Capacity Information
    let currentCapacity: Int // mAh
    let maxCapacity: Int // mAh
    let designCapacity: Int // mAh
    
    // Temperature
    let temperature: Double? // Celsius, nil if unavailable
    
    // Power Source
    let powerSource: String // "Battery" or "AC Power"
    
    // Computed Properties
    var isFullyCharged: Bool {
        percentage >= 100
    }
    
    var healthStatus: String {
        if health >= 80 {
            return "Excellent"
        } else if health >= 60 {
            return "Good"
        } else if health >= 40 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    var timeRemainingFormatted: String {
        guard let minutes = timeRemaining else {
            return "Calculating..."
        }
        
        if minutes == 0 {
            return "Fully Charged"
        }
        
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
    
    var temperatureFormatted: String {
        guard let temp = temperature else {
            return "N/A"
        }
        return String(format: "%.1f°C", temp)
    }
    
    var temperatureFahrenheit: Double? {
        guard let temp = temperature else {
            return nil
        }
        return (temp * 9/5) + 32
    }
    
    var voltageFormatted: String {
        String(format: "%.2f V", voltage)
    }
    
    var amperageFormatted: String {
        String(format: "%.0f mA", amperage * 1000)
    }
    
    var wattsFormatted: String {
        String(format: "%.2f W", abs(watts))
    }
    
    var chargingStatus: String {
        if isFullyCharged {
            return "Fully Charged"
        } else if isCharging {
            return "Charging"
        } else if isPluggedIn && !isCharging {
            return "Plugged In (Not Charging)"
        } else {
            return "On Battery"
        }
    }
    
    // Static placeholder for error states
    static var unavailable: BatteryInfo {
        BatteryInfo(
            percentage: 0,
            isCharging: false,
            isPluggedIn: true,
            timeRemaining: nil,
            health: 0,
            cycleCount: 0,
            condition: "N/A",
            voltage: 0.0,
            amperage: 0.0,
            watts: 0.0,
            currentCapacity: 0,
            maxCapacity: 0,
            designCapacity: 0,
            temperature: nil,
            powerSource: "Unknown"
        )
    }
}
