//
//  BatteryManagerApp.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import SwiftUI

@main
struct BatteryManagerApp: App {
    @StateObject private var viewModel = BatteryViewModel()
    
    init() {
        // Request notification permissions on launch (with improved error handling)
        AlertManager.shared.requestPermission { granted in
            if granted {
                print("✅ Notification permission granted - alerts will work")
            } else {
                print("⚠️ Notification permission not granted - alerts will be disabled")
                print("💡 To enable alerts:")
                print("   Option 1: Open System Settings > Notifications > Battery Manager and enable notifications")
                print("   Option 2: In Xcode, add the entitlements file to your target:")
                print("           - Select BatteryManager target")
                print("           - Go to 'Signing & Capabilities'")
                print("           - Click '+' and ensure the entitlements file is linked")
                print("   Option 3: Or disable App Sandbox in Build Settings (not recommended for production)")
            }
        }
    }
    
    var body: some Scene {
        // Menu Bar Extra
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: batteryIcon)
                    .foregroundColor(batteryColor)
                Text("\(viewModel.batteryInfo?.percentage ?? 0)%")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
        
        // Dashboard Window
        Window("Battery Dashboard", id: "dashboard") {
            DashboardView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
    
    // MARK: - Menu Bar Icon
    
    private var batteryIcon: String {
        guard let info = viewModel.batteryInfo else {
            return "battery.0"
        }
        
        if info.isCharging {
            return "bolt.fill"
        } else if info.percentage <= 20 {
            return "battery.25"
        } else if info.percentage <= 50 {
            return "battery.50"
        } else if info.percentage <= 75 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        guard let info = viewModel.batteryInfo else {
            return .gray
        }
        
        if info.isCharging {
            return .green
        } else if info.percentage <= 20 {
            return .red
        } else if info.percentage <= 50 {
            return .orange
        } else {
            return .white
        }
    }
}
