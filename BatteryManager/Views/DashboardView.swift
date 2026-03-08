//
//  DashboardView.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import SwiftUI
import UserNotifications

struct DashboardView: View {
    @ObservedObject var viewModel: BatteryViewModel
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if !viewModel.hasBattery {
                noBatteryView
            } else if let batteryInfo = viewModel.batteryInfo {
                mainContent(batteryInfo: batteryInfo)
            } else {
                errorView
            }
        }
        .frame(minWidth: 700, minHeight: 800)
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Main Content
    
    private func mainContent(batteryInfo: BatteryInfo) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                header
                
                // Large battery percentage card
                LargeBatteryCard(
                    percentage: batteryInfo.percentage,
                    isCharging: batteryInfo.isCharging,
                    status: batteryInfo.chargingStatus
                )
                
                // Quick stats grid
                quickStatsGrid(batteryInfo: batteryInfo)
                
                // Health visualization
                HealthProgressBar(
                    health: batteryInfo.health,
                    currentCycles: batteryInfo.cycleCount
                )
                
                // Power graph
                ChargingPowerGraph(history: viewModel.batteryHistory)
                
                // Capacity indicator
                CapacityIndicator(
                    current: batteryInfo.currentCapacity,
                    max: batteryInfo.maxCapacity,
                    design: batteryInfo.designCapacity
                )
                
                // Detailed information
                detailedInfoSection(batteryInfo: batteryInfo)
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Battery Manager")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.primary)
                
                Text("Real-time battery monitoring")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondary)
            }
            
            Spacer()
            
            HStack(spacing: Theme.Spacing.md) {
                // Refresh button
                Button(action: {
                    viewModel.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: Theme.IconSize.medium))
                        .foregroundColor(Theme.Colors.primary)
                }
                .buttonStyle(.plain)
                
                // Settings button
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: Theme.IconSize.medium))
                        .foregroundColor(Theme.Colors.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Quick Stats Grid
    
    private func quickStatsGrid(batteryInfo: BatteryInfo) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Theme.Spacing.md) {
            BatteryCardComponent(
                icon: "heart.fill",
                title: "Health",
                value: "\(batteryInfo.health)%",
                subtitle: batteryInfo.healthStatus,
                color: healthColor(batteryInfo.health)
            )
            
            BatteryCardComponent(
                icon: "arrow.circlepath",
                title: "Cycle Count",
                value: "\(batteryInfo.cycleCount)",
                subtitle: batteryInfo.condition
            )
            
            BatteryCardComponent(
                icon: "clock",
                title: "Time Remaining",
                value: batteryInfo.timeRemainingFormatted,
                subtitle: nil
            )
            
            BatteryCardComponent(
                icon: "bolt.fill",
                title: "Power",
                value: batteryInfo.wattsFormatted,
                subtitle: batteryInfo.isCharging ? "Charging" : "Discharging",
                color: batteryInfo.isCharging ? Theme.Colors.success : Theme.Colors.warning
            )
            
            BatteryCardComponent(
                icon: "powerplug.fill",
                title: "Power Source",
                value: batteryInfo.powerSource,
                subtitle: nil
            )
            
            BatteryCardComponent(
                icon: "thermometer",
                title: "Temperature",
                value: batteryInfo.temperatureFormatted,
                subtitle: nil
            )
        }
    }
    
    // MARK: - Detailed Info Section
    
    private func detailedInfoSection(batteryInfo: BatteryInfo) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Detailed Information")
                .font(Theme.Typography.title2)
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, Theme.Spacing.md)
            
            VStack(spacing: 0) {
                InfoRow(
                    icon: "bolt",
                    title: "Voltage",
                    value: batteryInfo.voltageFormatted
                )
                
                Divider()
                    .background(Theme.Colors.border)
                
                InfoRow(
                    icon: "waveform.path.ecg",
                    title: "Amperage",
                    value: batteryInfo.amperageFormatted
                )
                
                Divider()
                    .background(Theme.Colors.border)
                
                InfoRow(
                    icon: "battery.100",
                    title: "Current Capacity",
                    value: "\(batteryInfo.currentCapacity) mAh"
                )
                
                Divider()
                    .background(Theme.Colors.border)
                
                InfoRow(
                    icon: "battery.75",
                    title: "Max Capacity",
                    value: "\(batteryInfo.maxCapacity) mAh"
                )
                
                Divider()
                    .background(Theme.Colors.border)
                
                InfoRow(
                    icon: "battery.50",
                    title: "Design Capacity",
                    value: "\(batteryInfo.designCapacity) mAh"
                )
                
                Divider()
                    .background(Theme.Colors.border)
                
                InfoRow(
                    icon: "checkmark.seal.fill",
                    title: "Condition",
                    value: batteryInfo.condition,
                    color: conditionColor(batteryInfo.condition)
                )
            }
            .padding(Theme.Spacing.md)
            .cardStyle()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.Colors.primary)
            
            Text("Loading battery information...")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.secondary)
        }
    }
    
    // MARK: - No Battery View
    
    private var noBatteryView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "battery.0")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.secondary)
            
            Text("No Battery Detected")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.primary)
            
            Text("This Mac does not appear to have a battery.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xxl)
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.danger)
            
            Text("Error")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.primary)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                viewModel.refresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.Spacing.xxl)
    }
    
    // MARK: - Helper Functions
    
    private func healthColor(_ health: Int) -> Color {
        if health >= 80 {
            return Theme.Colors.success
        } else if health >= 60 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.danger
        }
    }
    
    private func conditionColor(_ condition: String) -> Color {
        switch condition.lowercased() {
        case "normal", "good":
            return Theme.Colors.success
        case "replace soon", "fair":
            return Theme.Colors.warning
        default:
            return Theme.Colors.danger
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: BatteryViewModel
    @Environment(\.dismiss) var dismiss
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                HStack {
                    Text("Settings")
                        .font(Theme.Typography.largeTitle)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Spacer()
                    
                    Button("Done") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.lg)
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Notification status banner
                        if notificationStatus != .authorized {
                            notificationStatusBanner
                        }
                        
                        // Alert Settings
                        alertSettings
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private var notificationStatusBanner: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.Colors.warning)
                
                Text("Notifications Not Enabled")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Text("Battery alerts require notification permissions. Please enable notifications in System Settings > Notifications > Battery Manager, or add the entitlements file to your Xcode project.")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Button("Check Again") {
                checkNotificationStatus()
            }
            .buttonStyle(.bordered)
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.warning.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Theme.Colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private var alertSettings: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Alerts")
                .font(Theme.Typography.title2)
                .foregroundColor(Theme.Colors.primary)
            
            VStack(spacing: Theme.Spacing.md) {
                // Enable alerts toggle
                Toggle(isOn: $viewModel.alertsEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Theme.Colors.secondary)
                        Text("Enable Alerts")
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .toggleStyle(.switch)
                
                if !viewModel.alertsEnabled {
                    Text("Enable Alerts to activate notifications and custom functions below.")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.warning)
                }

                Divider()
                    .background(Theme.Colors.border)
                
                // Low battery alert
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Toggle(isOn: $viewModel.lowBatteryAlertEnabled) {
                        HStack {
                            Image(systemName: "battery.25")
                                .foregroundColor(Theme.Colors.danger)
                            Text("Low Battery Alert")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .toggleStyle(.switch)
                    .disabled(!viewModel.alertsEnabled)
                    
                    if viewModel.lowBatteryAlertEnabled {
                        HStack {
                            Text("Threshold:")
                                .foregroundColor(Theme.Colors.secondary)
                            Slider(value: Binding(
                                get: { Double(viewModel.lowBatteryThreshold) },
                                set: { viewModel.lowBatteryThreshold = Int($0) }
                            ), in: 5...30, step: 5)
                            .disabled(!viewModel.alertsEnabled)
                            Text("\(viewModel.lowBatteryThreshold)%")
                                .foregroundColor(Theme.Colors.primary)
                                .monospacedDigit()
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                
                Divider()
                    .background(Theme.Colors.border)
                
                // High battery alert
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Toggle(isOn: $viewModel.highBatteryAlertEnabled) {
                        HStack {
                            Image(systemName: "battery.100")
                                .foregroundColor(Theme.Colors.success)
                            Text("High Battery Alert")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .toggleStyle(.switch)
                    .disabled(!viewModel.alertsEnabled)
                    
                    if viewModel.highBatteryAlertEnabled {
                        HStack {
                            Text("Threshold:")
                                .foregroundColor(Theme.Colors.secondary)
                            Slider(value: Binding(
                                get: { Double(viewModel.highBatteryThreshold) },
                                set: { viewModel.highBatteryThreshold = Int($0) }
                            ), in: 70...100, step: 5)
                            .disabled(!viewModel.alertsEnabled)
                            Text("\(viewModel.highBatteryThreshold)%")
                                .foregroundColor(Theme.Colors.primary)
                                .monospacedDigit()
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }

                Divider()
                    .background(Theme.Colors.border)

                // Custom level alerts
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Toggle(isOn: $viewModel.customLevelAlertsEnabled) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(Theme.Colors.secondary)
                            Text("Custom Level Alerts")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .toggleStyle(.switch)
                    .disabled(!viewModel.alertsEnabled)

                    if viewModel.customLevelAlertsEnabled {
                        TextField("Levels (comma-separated, e.g. 15,30,80)", text: $viewModel.customAlertLevelsInput)
                            .textFieldStyle(.roundedBorder)
                            .disabled(!viewModel.alertsEnabled)

                        Text("Triggers when the battery crosses these levels in either direction.")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.tertiary)
                    }
                }

                Divider()
                    .background(Theme.Colors.border)

                // Critical low-battery warning
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Toggle(isOn: $viewModel.criticalBatteryAlertEnabled) {
                        HStack {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundColor(Theme.Colors.danger)
                            Text("Critical Battery Warning")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .toggleStyle(.switch)
                    .disabled(!viewModel.alertsEnabled)

                    if viewModel.criticalBatteryAlertEnabled {
                        HStack {
                            Text("Threshold:")
                                .foregroundColor(Theme.Colors.secondary)
                            Slider(value: Binding(
                                get: { Double(viewModel.criticalBatteryThreshold) },
                                set: { viewModel.criticalBatteryThreshold = Int($0) }
                            ), in: 2...15, step: 1)
                            .disabled(!viewModel.alertsEnabled)
                            Text("\(viewModel.criticalBatteryThreshold)%")
                                .foregroundColor(Theme.Colors.primary)
                                .monospacedDigit()
                                .frame(width: 40, alignment: .trailing)
                        }

                        Text("Warning-only mode: macOS does not allow normal apps to force shutdown safely without privileged helpers.")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.tertiary)
                    }
                }

                Divider()
                    .background(Theme.Colors.border)

                // Charge-limit note
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        Image(systemName: "lock.slash")
                            .foregroundColor(Theme.Colors.warning)
                        Text("Charge Limit Control")
                            .foregroundColor(Theme.Colors.primary)
                            .font(Theme.Typography.headline)
                    }

                    Text("Directly stopping charging at 80% is not available through public macOS app APIs. Use macOS Optimized Battery Charging or a driver-based utility for hard charge caps.")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.tertiary)
                }
            }
            .padding(Theme.Spacing.md)
            .cardStyle()
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView(viewModel: BatteryViewModel())
}
