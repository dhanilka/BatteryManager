//
//  AppUsageService.swift
//  BatteryManager
//
//  Created by Codex on 3/8/26.
//

import AppKit
import Foundation

struct AppBatteryUsage: Identifiable {
    let id: String
    let name: String
    let cpuPercent: Double
    let relativeBatteryPercent: Double
}

final class AppUsageService {
    static let shared = AppUsageService()

    private init() {}

    func topBatteryUsageApps(limit: Int = 4) -> [AppBatteryUsage] {
        let processRows = runningProcessCPURows()
        guard !processRows.isEmpty else {
            return []
        }

        var groupedByName: [String: Double] = [:]
        for row in processRows {
            guard row.cpuPercent > 0.1 else { continue }
            let appName = resolvedAppName(pid: row.pid, commandPath: row.commandPath)
            groupedByName[appName, default: 0.0] += row.cpuPercent
        }

        let sorted = groupedByName
            .map { (name: $0.key, cpuPercent: $0.value) }
            .sorted { $0.cpuPercent > $1.cpuPercent }
            .prefix(limit)

        let top = Array(sorted)
        let totalTopCPU = top.reduce(0.0) { $0 + $1.cpuPercent }
        guard totalTopCPU > 0 else {
            return []
        }

        return top.map {
            AppBatteryUsage(
                id: $0.name,
                name: $0.name,
                cpuPercent: $0.cpuPercent,
                relativeBatteryPercent: ($0.cpuPercent / totalTopCPU) * 100.0
            )
        }
    }

    private func runningProcessCPURows() -> [(pid: Int32, cpuPercent: Double, commandPath: String)] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-A", "-o", "pid=,%cpu=,comm="]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return output
            .split(separator: "\n")
            .compactMap { line -> (pid: Int32, cpuPercent: Double, commandPath: String)? in
                let parts = line.trimmingCharacters(in: .whitespaces)
                    .split(maxSplits: 2, whereSeparator: { $0.isWhitespace })

                guard parts.count == 3,
                      let pid = Int32(parts[0]),
                      let cpuPercent = Double(parts[1]) else {
                    return nil
                }

                return (pid: pid, cpuPercent: cpuPercent, commandPath: String(parts[2]))
            }
    }

    private func resolvedAppName(pid: Int32, commandPath: String) -> String {
        if let app = NSRunningApplication(processIdentifier: pid),
           let name = app.localizedName,
           !name.isEmpty {
            return name
        }

        return URL(fileURLWithPath: commandPath).lastPathComponent
    }
}
