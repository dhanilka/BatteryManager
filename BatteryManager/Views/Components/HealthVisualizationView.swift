//
//  HealthVisualizationView.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import SwiftUI
import Charts

// MARK: - Health Progress Bar

struct HealthProgressBar: View {
    let health: Int
    let maxCycles: Int = 1000 // Typical MacBook battery rated for 1000 cycles
    let currentCycles: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(healthColor)
                Text("Battery Health")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
                
                Spacer()
                
                Text("\(health)%")
                    .font(Theme.Typography.title2)
                    .foregroundColor(healthColor)
            }
            
            // Health progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Theme.Colors.border)
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(healthGradient)
                        .frame(width: geometry.size.width * CGFloat(health) / 100.0, height: 12)
                        .animation(Theme.Animation.smooth, value: health)
                }
            }
            .frame(height: 12)
            
            // Cycle count progress bar
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "arrow.circlepath")
                        .foregroundColor(Theme.Colors.secondary)
                    Text("Cycle Count: \(currentCycles) / \(maxCycles)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Theme.Colors.border)
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(cycleColor)
                            .frame(
                                width: geometry.size.width * min(CGFloat(currentCycles) / CGFloat(maxCycles), 1.0),
                                height: 8
                            )
                            .animation(Theme.Animation.smooth, value: currentCycles)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
    
    private var healthColor: Color {
        if health >= 80 {
            return Theme.Colors.success
        } else if health >= 60 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.danger
        }
    }
    
    private var healthGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [healthColor.opacity(0.7), healthColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var cycleColor: Color {
        let percentage = Double(currentCycles) / Double(maxCycles)
        if percentage < 0.5 {
            return Theme.Colors.success
        } else if percentage < 0.8 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.danger
        }
    }
}

// MARK: - Charging Power Graph

struct ChargingPowerGraph: View {
    let history: [BatteryHistoryPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Theme.Colors.secondary)
                Text("Power History")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
                
                Spacer()
                
                if let latest = history.last {
                    Text(String(format: "%.1f W", abs(latest.watts)))
                        .font(Theme.Typography.body.weight(.semibold))
                        .foregroundColor(latest.isCharging ? Theme.Colors.success : Theme.Colors.warning)
                }
            }
            
            // Chart
            if history.isEmpty {
                Text("Collecting data...")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 150)
            } else {
                Chart {
                    ForEach(history) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Watts", abs(point.watts))
                        )
                        .foregroundStyle(point.isCharging ? Theme.Colors.success : Theme.Colors.warning)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Watts", abs(point.watts))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    (point.isCharging ? Theme.Colors.success : Theme.Colors.warning).opacity(0.3),
                                    (point.isCharging ? Theme.Colors.success : Theme.Colors.warning).opacity(0.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.Colors.border)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Theme.Colors.border)
                        AxisValueLabel {
                            if let watts = value.as(Double.self) {
                                Text(String(format: "%.0f W", watts))
                                    .font(Theme.Typography.caption2)
                                    .foregroundColor(Theme.Colors.tertiary)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Capacity Indicator

struct CapacityIndicator: View {
    let current: Int
    let max: Int
    let design: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "battery.75")
                    .foregroundColor(Theme.Colors.secondary)
                Text("Capacity")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
            }
            
            // Capacity bars
            VStack(spacing: Theme.Spacing.md) {
                // Design capacity
                capacityRow(
                    label: "Design",
                    value: design,
                    color: Theme.Colors.tertiary,
                    maxValue: design
                )
                
                // Max capacity
                capacityRow(
                    label: "Maximum",
                    value: max,
                    color: Theme.Colors.secondary,
                    maxValue: design
                )
                
                // Current capacity
                capacityRow(
                    label: "Current",
                    value: current,
                    color: Theme.Colors.primary,
                    maxValue: design
                )
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
    
    private func capacityRow(label: String, value: Int, color: Color, maxValue: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(value) mAh")
                    .font(Theme.Typography.caption)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Theme.Colors.border)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * CGFloat(value) / CGFloat(maxValue),
                            height: 6
                        )
                        .animation(Theme.Animation.smooth, value: value)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                HealthProgressBar(health: 92, currentCycles: 147)
                
                ChargingPowerGraph(history: [
                    BatteryHistoryPoint(timestamp: Date().addingTimeInterval(-60), percentage: 80, watts: 15.5, isCharging: true),
                    BatteryHistoryPoint(timestamp: Date().addingTimeInterval(-45), percentage: 82, watts: 16.2, isCharging: true),
                    BatteryHistoryPoint(timestamp: Date().addingTimeInterval(-30), percentage: 84, watts: 14.8, isCharging: true),
                    BatteryHistoryPoint(timestamp: Date().addingTimeInterval(-15), percentage: 86, watts: 15.1, isCharging: true),
                    BatteryHistoryPoint(timestamp: Date(), percentage: 88, watts: 14.5, isCharging: true)
                ])
                
                CapacityIndicator(current: 4850, max: 5250, design: 5700)
            }
            .padding()
        }
    }
}
