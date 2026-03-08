//
//  BatteryService.swift
//  BatteryManager
//
//  Created by Dhanilka Dasanayake on 3/8/26.
//

import Foundation
import IOKit
import IOKit.ps

class BatteryService {
    static let shared = BatteryService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func getBatteryInfo() -> BatteryInfo? {
        let iopsDescription = getPowerSourceDescription()
        let smartBatteryProperties = getSmartBatteryProperties()

        if iopsDescription == nil && smartBatteryProperties == nil {
            return nil
        }
        
        return parseBatteryInfo(
            iops: iopsDescription ?? [:],
            smartBattery: smartBatteryProperties ?? [:]
        )
    }
    
    // MARK: - Private Methods
    
    private func getPowerSourceDescription() -> [String: Any]? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return nil
        }

        return description
    }

    private func getSmartBatteryProperties() -> [String: Any]? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else {
            return nil
        }
        defer { IOObjectRelease(service) }

        var propertiesRef: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &propertiesRef, kCFAllocatorDefault, 0)
        guard result == KERN_SUCCESS,
              let properties = propertiesRef?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        return properties
    }

    private func parseBatteryInfo(iops: [String: Any], smartBattery: [String: Any]) -> BatteryInfo {
        // Basic Information
        let rawPercentageCandidate = intValue(from: iops[kIOPSCurrentCapacityKey]) ??
            intValue(from: smartBattery["CurrentCapacity"]) ?? 0
        let isCharging = boolValue(from: iops[kIOPSIsChargingKey]) ??
            boolValue(from: smartBattery["IsCharging"]) ?? false
        let isPluggedInFromIOPS = (iops[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        let isPluggedIn = isPluggedInFromIOPS || (boolValue(from: smartBattery["ExternalConnected"]) ?? false)
        
        // Capacity Information
        let designCapacity = positiveIntValue(from: smartBattery["DesignCapacity"]) ??
            positiveIntValue(from: iops[kIOPSDesignCapacityKey]) ?? 0

        let maxCapacity = resolveMaxCapacity(
            rawMax: positiveIntValue(from: smartBattery["AppleRawMaxCapacity"]),
            nominal: positiveIntValue(from: smartBattery["NominalChargeCapacity"]),
            iopsMax: positiveIntValue(from: iops[kIOPSMaxCapacityKey]),
            designCapacity: designCapacity
        )

        let currentCapacity = resolveCurrentCapacity(
            rawCurrent: positiveIntValue(from: smartBattery["AppleRawCurrentCapacity"]),
            iopsCurrent: positiveIntValue(from: iops[kIOPSCurrentCapacityKey]),
            percentage: rawPercentageCandidate,
            maxCapacity: maxCapacity
        )

        let percentage = resolvePercentage(
            rawPercentage: rawPercentageCandidate,
            iopsMaxCapacity: intValue(from: iops[kIOPSMaxCapacityKey]),
            currentCapacity: currentCapacity,
            maxCapacity: maxCapacity
        )

        // Time Remaining (in minutes)
        let iopsTimeToEmpty = positiveIntValue(from: iops[kIOPSTimeToEmptyKey])
        let iopsTimeToFull = positiveIntValue(from: iops[kIOPSTimeToFullChargeKey])
        let smartTimeToEmpty = positiveIntValue(from: smartBattery["AvgTimeToEmpty"]) ??
            positiveIntValue(from: smartBattery["TimeRemaining"])
        let smartTimeToFull = positiveIntValue(from: smartBattery["AvgTimeToFull"])

        let timeRemaining: Int? = {
            if isCharging {
                return iopsTimeToFull ?? smartTimeToFull
            }

            if percentage >= 100 && isPluggedIn {
                return 0
            }

            return iopsTimeToEmpty ?? smartTimeToEmpty
        }()
        
        // Health Calculation
        let health = (designCapacity > 0 && maxCapacity > 0)
            ? Int((Double(maxCapacity) / Double(designCapacity)) * 100.0)
            : 100
        
        // Cycle Count
        let cycleCount = positiveIntValue(from: smartBattery["CycleCount"]) ??
            positiveIntValue(from: iops["CycleCount"]) ?? 0
        
        // Battery Condition
        let condition = resolvedCondition(
            iopsCondition: iops["BatteryHealth"] as? String,
            permanentFailureStatus: positiveIntValue(from: smartBattery["PermanentFailureStatus"]),
            health: health
        )
        
        // Electrical Properties
        let voltageMilliVolts = positiveIntValue(from: smartBattery["Voltage"]) ??
            positiveIntValue(from: iops[kIOPSVoltageKey]) ?? 0
        let amperageMilliAmps = signedIntValue(from: smartBattery["Amperage"]) ??
            signedIntValue(from: iops[kIOPSCurrentKey]) ?? 0
        let voltage = Double(voltageMilliVolts) / 1000.0
        let amperage = Double(amperageMilliAmps) / 1000.0
        let watts = voltage * amperage
        
        // Temperature (if available)
        let temperatureRaw = positiveIntValue(from: smartBattery["Temperature"]) ??
            positiveIntValue(from: iops["Temperature"])
        let temperature = temperatureRaw.map { Double($0) / 100.0 }
        
        // Power Source
        let powerSource = isPluggedIn ? "AC Power" : "Battery"
        
        return BatteryInfo(
            percentage: percentage,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            timeRemaining: timeRemaining,
            health: health,
            cycleCount: cycleCount,
            condition: normalizeCondition(condition),
            voltage: voltage,
            amperage: amperage,
            watts: watts,
            currentCapacity: currentCapacity,
            maxCapacity: maxCapacity,
            designCapacity: designCapacity,
            temperature: temperature,
            powerSource: powerSource
        )
    }
    
    private func normalizeCondition(_ condition: String) -> String {
        // Normalize various battery condition strings
        switch condition.lowercased() {
        case "good", "normal":
            return "Normal"
        case "fair", "replace soon":
            return "Replace Soon"
        case "poor", "replace now":
            return "Replace Now"
        case "check battery", "service battery":
            return "Service Battery"
        default:
            return condition
        }
    }

    private func resolvedCondition(iopsCondition: String?, permanentFailureStatus: Int?, health: Int) -> String {
        if let iopsCondition, !iopsCondition.isEmpty {
            return normalizeCondition(iopsCondition)
        }

        if let permanentFailureStatus, permanentFailureStatus > 0 {
            return "Service Battery"
        }

        if health >= 80 {
            return "Normal"
        } else if health >= 60 {
            return "Replace Soon"
        } else if health > 0 {
            return "Service Battery"
        } else {
            return "N/A"
        }
    }

    private func resolveMaxCapacity(rawMax: Int?, nominal: Int?, iopsMax: Int?, designCapacity: Int) -> Int {
        if let rawMax, rawMax > 0 {
            return rawMax
        }

        if let nominal, nominal > 0 {
            return nominal
        }

        if let iopsMax, iopsMax > 0 {
            // IOPS often reports 0...100 percentages instead of mAh for capacity fields.
            if iopsMax <= 100 && designCapacity > 1000 {
                return designCapacity
            }
            return iopsMax
        }

        return max(designCapacity, 0)
    }

    private func resolveCurrentCapacity(rawCurrent: Int?, iopsCurrent: Int?, percentage: Int, maxCapacity: Int) -> Int {
        if let rawCurrent, rawCurrent > 0 {
            return rawCurrent
        }

        if let iopsCurrent, iopsCurrent > 0 {
            if iopsCurrent <= 100 && maxCapacity > 100 {
                return Int((Double(iopsCurrent) / 100.0) * Double(maxCapacity))
            }
            return iopsCurrent
        }

        if percentage > 0 && maxCapacity > 0 {
            return Int((Double(percentage) / 100.0) * Double(maxCapacity))
        }

        return 0
    }

    private func resolvePercentage(
        rawPercentage: Int,
        iopsMaxCapacity: Int?,
        currentCapacity: Int,
        maxCapacity: Int
    ) -> Int {
        if (0...100).contains(rawPercentage) {
            return rawPercentage
        }

        if let iopsMaxCapacity,
           iopsMaxCapacity > 100,
           rawPercentage > 0,
           rawPercentage <= iopsMaxCapacity {
            return Int((Double(rawPercentage) / Double(iopsMaxCapacity)) * 100.0)
        }

        if currentCapacity > 0 && maxCapacity > 0 {
            return Int((Double(currentCapacity) / Double(maxCapacity)) * 100.0)
        }

        return min(max(rawPercentage, 0), 100)
    }

    private func boolValue(from value: Any?) -> Bool? {
        guard let value else { return nil }

        if let bool = value as? Bool {
            return bool
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        if let string = value as? String {
            switch string.lowercased() {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return nil
            }
        }

        return nil
    }

    private func positiveIntValue(from value: Any?) -> Int? {
        guard let intValue = intValue(from: value), intValue > 0 else {
            return nil
        }
        return intValue
    }

    private func signedIntValue(from value: Any?) -> Int? {
        guard let signed64 = signedInt64Value(from: value),
              signed64 >= Int64(Int.min),
              signed64 <= Int64(Int.max) else {
            return nil
        }

        return Int(signed64)
    }

    private func intValue(from value: Any?) -> Int? {
        guard let intValue = signedIntValue(from: value), intValue >= 0 else {
            return nil
        }
        return intValue
    }

    private func signedInt64Value(from value: Any?) -> Int64? {
        guard let value else { return nil }

        if let int = value as? Int {
            return Int64(int)
        }

        if let int8 = value as? Int8 {
            return Int64(int8)
        }

        if let int16 = value as? Int16 {
            return Int64(int16)
        }

        if let int32 = value as? Int32 {
            return Int64(int32)
        }

        if let int64 = value as? Int64 {
            return int64
        }

        if let uint = value as? UInt {
            return Int64(bitPattern: UInt64(uint))
        }

        if let uint8 = value as? UInt8 {
            return Int64(bitPattern: UInt64(uint8))
        }

        if let uint16 = value as? UInt16 {
            return Int64(bitPattern: UInt64(uint16))
        }

        if let uint32 = value as? UInt32 {
            return Int64(bitPattern: UInt64(uint32))
        }

        if let uint64 = value as? UInt64 {
            return Int64(bitPattern: uint64)
        }

        if let number = value as? NSNumber {
            let objCType = String(cString: number.objCType)
            let unsignedTypes: Set<String> = ["C", "I", "S", "L", "Q"]
            if unsignedTypes.contains(objCType) {
                return Int64(bitPattern: number.uint64Value)
            }
            return number.int64Value
        }

        if let string = value as? String {
            if let signed = Int64(string) {
                return signed
            }
            if let unsigned = UInt64(string) {
                return Int64(bitPattern: unsigned)
            }
        }

        return nil
    }
    
    // MARK: - Battery Availability Check
    
    func hasBattery() -> Bool {
        if getSmartBatteryProperties() != nil {
            return true
        }

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return false
        }
        
        return !sources.isEmpty
    }
}
