//
//  BatteryCardComponent.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import SwiftUI

struct BatteryCardComponent: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    
    init(icon: String, title: String, value: String, subtitle: String? = nil, color: Color = Theme.Colors.primary) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with icon and title
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: Theme.IconSize.small))
                    .foregroundColor(Theme.Colors.secondary)
                
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondary)
            }
            
            // Main value
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            // Subtitle (optional)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Large Battery Card (for main percentage display)

struct LargeBatteryCard: View {
    let percentage: Int
    let isCharging: Bool
    let status: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Battery icon with percentage
            ZStack {
                // Background circle
                Circle()
                    .stroke(Theme.Colors.border, lineWidth: 8)
                    .frame(width: 180, height: 180)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100.0)
                    .stroke(
                        batteryColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.smooth, value: percentage)
                
                // Center content
                VStack(spacing: 4) {
                    if isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 24))
                            .foregroundColor(batteryColor)
                    }
                    
                    Text("\(percentage)%")
                        .font(Theme.Typography.monoLarge)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            // Status text
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.system(size: Theme.IconSize.small))
                    .foregroundColor(batteryColor)
                
                Text(status)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .cardStyle()
    }
    
    private var batteryColor: Color {
        if isCharging {
            return Theme.Colors.success
        } else if percentage <= 20 {
            return Theme.Colors.danger
        } else if percentage <= 50 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.success
        }
    }
    
    private var statusIcon: String {
        if isCharging {
            return "bolt.fill"
        } else if percentage <= 20 {
            return "exclamationmark.triangle.fill"
        } else {
            return "battery.100"
        }
    }
}

// MARK: - Info Row (for detailed list items)

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    init(icon: String, title: String, value: String, color: Color = Theme.Colors.primary) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: Theme.IconSize.medium))
                .foregroundColor(Theme.Colors.secondary)
                .frame(width: 32)
            
            // Title
            Text(title)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondary)
            
            Spacer()
            
            // Value
            Text(value)
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundColor(color)
                .monospacedDigit()
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        
        VStack(spacing: Theme.Spacing.md) {
            BatteryCardComponent(
                icon: "heart.fill",
                title: "Health",
                value: "92%",
                subtitle: "Excellent",
                color: Theme.Colors.success
            )
            
            BatteryCardComponent(
                icon: "arrow.circlepath",
                title: "Cycle Count",
                value: "147",
                subtitle: nil
            )
            
            LargeBatteryCard(
                percentage: 85,
                isCharging: true,
                status: "Charging"
            )
            
            InfoRow(
                icon: "bolt.fill",
                title: "Voltage",
                value: "12.58 V"
            )
        }
        .padding()
    }
}
