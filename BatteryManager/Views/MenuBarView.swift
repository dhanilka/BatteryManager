//
//  MenuBarView.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: BatteryViewModel
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let batteryInfo = viewModel.batteryInfo {
                // Header
                menuHeader(batteryInfo: batteryInfo)
                
                Divider()
                    .background(Theme.Colors.border)
                    .padding(.vertical, Theme.Spacing.sm)
                
                // Quick stats
                quickStats(batteryInfo: batteryInfo)
                
                Divider()
                    .background(Theme.Colors.border)
                    .padding(.vertical, Theme.Spacing.sm)

                // Top power apps
                topAppsSection
                
                Divider()
                    .background(Theme.Colors.border)
                    .padding(.vertical, Theme.Spacing.sm)
                
                // Actions
                menuActions
            } else {
                loadingOrError
            }
        }
        .padding(Theme.Spacing.md)
        .frame(width: 320)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Menu Header
    
    private func menuHeader(batteryInfo: BatteryInfo) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack(alignment: .center) {
                Image(systemName: batterySymbolName(for: batteryInfo))
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(batteryColor(batteryInfo))

                if batteryInfo.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(batteryInfo.percentage)%")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primary)
                
                Text(batteryInfo.chargingStatus)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondary)
            }
        }
    }
    
    // MARK: - Quick Stats
    
    private func quickStats(batteryInfo: BatteryInfo) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            statRow(
                icon: "heart.fill",
                label: "Health",
                value: "\(batteryInfo.health)%",
                valueColor: healthColor(batteryInfo.health)
            )
            
            statRow(
                icon: "arrow.circlepath",
                label: "Cycles",
                value: "\(batteryInfo.cycleCount)"
            )
            
            statRow(
                icon: "bolt.fill",
                label: "Power",
                value: batteryInfo.wattsFormatted
            )
            
            statRow(
                icon: "clock",
                label: "Time",
                value: batteryInfo.timeRemainingFormatted
            )

            statRow(
                icon: "powerplug.fill",
                label: "Source",
                value: batteryInfo.powerSource
            )

            statRow(
                icon: "clock.arrow.circlepath",
                label: "Last Charge",
                value: viewModel.lastChargeTimeFormatted
            )
            
            statRow(
                icon: "thermometer",
                label: "Temperature",
                value: batteryInfo.temperatureFormatted
            )
        }
    }

    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondary)
                Text("Top Battery Usage Apps")
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundColor(Theme.Colors.secondary)
            }

            if viewModel.topBatteryApps.isEmpty {
                Text("Collecting app usage data...")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiary)
            } else {
                ForEach(viewModel.topBatteryApps) { app in
                    appUsageRow(app)
                }
            }
        }
    }

    private func appUsageRow(_ app: AppBatteryUsage) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(Theme.Colors.success)

            Text(app.name)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.primary)
                .lineLimit(1)

            Spacer()

            Text(String(format: "%.0f%%", app.relativeBatteryPercent))
                .font(Theme.Typography.caption.weight(.semibold))
                .foregroundColor(Theme.Colors.primary)
                .monospacedDigit()
        }
    }
    
    private func statRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = Theme.Colors.primary
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondary)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.caption.weight(.semibold))
                .foregroundColor(valueColor)
                .monospacedDigit()
                .lineLimit(1)
        }
    }
    
    // MARK: - Menu Actions
    
    private var menuActions: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: {
                openWindow(id: "dashboard")
            }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("Open Dashboard")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .foregroundColor(Theme.Colors.primary)
                .padding(Theme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.small)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                viewModel.refresh()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                    Spacer()
                }
                .foregroundColor(Theme.Colors.secondary)
                .padding(Theme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.small)
            }
            .buttonStyle(.plain)
            
            Divider()
                .background(Theme.Colors.border)
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                    Spacer()
                }
                .foregroundColor(Theme.Colors.danger)
                .padding(Theme.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.small)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Loading or Error
    
    private var loadingOrError: some View {
        VStack(spacing: Theme.Spacing.md) {
            if viewModel.isLoading {
                ProgressView()
                    .tint(Theme.Colors.primary)
                Text("Loading...")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.danger)
                Text(viewModel.errorMessage ?? "Unable to load battery info")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 100)
    }
    
    // MARK: - Helper Functions
    
    private func batteryColor(_ info: BatteryInfo) -> Color {
        if info.isCharging {
            return Theme.Colors.success
        } else if info.percentage <= 20 {
            return Theme.Colors.danger
        } else if info.percentage <= 50 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.success
        }
    }

    private func batterySymbolName(for info: BatteryInfo) -> String {
        if info.percentage <= 20 {
            return "battery.25"
        } else if info.percentage <= 50 {
            return "battery.50"
        } else if info.percentage <= 75 {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
    
    private func healthColor(_ health: Int) -> Color {
        if health >= 80 {
            return Theme.Colors.success
        } else if health >= 60 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.danger
        }
    }
}

// MARK: - Preview

#Preview {
    MenuBarView(viewModel: BatteryViewModel())
}
