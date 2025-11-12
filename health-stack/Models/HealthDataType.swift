//
//  HealthDataType.swift
//  health-stack
//

import Foundation
import HealthKit

enum HealthDataType: String, CaseIterable, Codable {
    // Body Measurements
    case height
    case bodyMass
    case bodyMassIndex
    case bodyFatPercentage
    case leanBodyMass
    case waistCircumference
    
    // Activity
    case stepCount
    case distanceWalkingRunning
    case flightsClimbed
    case activeEnergyBurned
    case basalEnergyBurned
    case exerciseTime
    case standHours
    
    // Cardiovascular
    case heartRate
    case restingHeartRate
    case heartRateVariability
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case oxygenSaturation
    
    // Sleep
    case sleepAnalysis
    case timeInBed
    
    // Nutrition
    case dietaryEnergy
    case dietaryEnergyConsumed
    case dietaryProtein
    case dietaryCarbohydrates
    case dietaryFat
    case dietaryFiber
    case dietarySugar
    case dietaryWater
    
    // Respiratory
    case respiratoryRate
    case vo2Max
    
    // Other
    case bloodGlucose
    case bodyTemperature
    case mindfulMinutes
    
    var category: HealthDataCategory {
        switch self {
        case .height, .bodyMass, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass, .waistCircumference:
            return .bodyMeasurements
        case .stepCount, .distanceWalkingRunning, .flightsClimbed, .activeEnergyBurned, .basalEnergyBurned, .exerciseTime, .standHours:
            return .activity
        case .heartRate, .restingHeartRate, .heartRateVariability, .bloodPressureSystolic, .bloodPressureDiastolic, .oxygenSaturation:
            return .cardiovascular
        case .sleepAnalysis, .timeInBed:
            return .sleep
        case .dietaryEnergy, .dietaryEnergyConsumed, .dietaryProtein, .dietaryCarbohydrates, .dietaryFat, .dietaryFiber, .dietarySugar, .dietaryWater:
            return .nutrition
        case .respiratoryRate, .vo2Max:
            return .respiratory
        case .bloodGlucose, .bodyTemperature, .mindfulMinutes:
            return .other
        }
    }
    
    var unit: HKUnit {
        switch self {
        case .height:
            return .meterUnit(with: .centi)
        case .bodyMass:
            return .gramUnit(with: .kilo)
        case .bodyMassIndex:
            return .count()
        case .bodyFatPercentage:
            return .percent()
        case .leanBodyMass:
            return .gramUnit(with: .kilo)
        case .waistCircumference:
            return .meterUnit(with: .centi)
        case .stepCount:
            return .count()
        case .distanceWalkingRunning:
            return .meter()
        case .flightsClimbed:
            return .count()
        case .activeEnergyBurned, .basalEnergyBurned, .dietaryEnergy, .dietaryEnergyConsumed:
            return .kilocalorie()
        case .exerciseTime:
            return .second() // Apple Exercise Time is stored in seconds
        case .standHours:
            return .second() // Apple Stand Time is stored in seconds
        case .heartRate, .restingHeartRate:
            return .count().unitDivided(by: .minute())
        case .heartRateVariability:
            return .secondUnit(with: .milli)
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return .millimeterOfMercury()
        case .oxygenSaturation:
            return .percent()
        case .sleepAnalysis, .timeInBed:
            return .minute()
        case .dietaryProtein, .dietaryCarbohydrates, .dietaryFat, .dietaryFiber, .dietarySugar:
            return .gram()
        case .dietaryWater:
            return .literUnit(with: .milli)
        case .respiratoryRate:
            return .count().unitDivided(by: .minute())
        case .vo2Max:
            return .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute())
        case .bloodGlucose:
            return .gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        case .bodyTemperature:
            return .degreeCelsius()
        case .mindfulMinutes:
            return .minute()
        }
    }
    
    var hkQuantityType: HKQuantityTypeIdentifier? {
        switch self {
        case .height:
            return .height
        case .bodyMass:
            return .bodyMass
        case .bodyMassIndex:
            return .bodyMassIndex
        case .bodyFatPercentage:
            return .bodyFatPercentage
        case .leanBodyMass:
            return .leanBodyMass
        case .waistCircumference:
            return .waistCircumference
        case .stepCount:
            return .stepCount
        case .distanceWalkingRunning:
            return .distanceWalkingRunning
        case .flightsClimbed:
            return .flightsClimbed
        case .activeEnergyBurned:
            return .activeEnergyBurned
        case .basalEnergyBurned:
            return .basalEnergyBurned
        case .exerciseTime:
            return .appleExerciseTime
        case .standHours:
            return .appleStandTime
        case .heartRate:
            return .heartRate
        case .restingHeartRate:
            return .restingHeartRate
        case .heartRateVariability:
            return .heartRateVariabilitySDNN
        case .bloodPressureSystolic:
            return .bloodPressureSystolic
        case .bloodPressureDiastolic:
            return .bloodPressureDiastolic
        case .oxygenSaturation:
            return .oxygenSaturation
        case .sleepAnalysis:
            return nil // HKCategoryType
        case .timeInBed:
            return nil // Derived from sleep analysis
        case .dietaryEnergy, .dietaryEnergyConsumed:
            return .dietaryEnergyConsumed
        case .dietaryProtein:
            return .dietaryProtein
        case .dietaryCarbohydrates:
            return .dietaryCarbohydrates
        case .dietaryFat:
            return .dietaryFatTotal
        case .dietaryFiber:
            return .dietaryFiber
        case .dietarySugar:
            return .dietarySugar
        case .dietaryWater:
            return .dietaryWater
        case .respiratoryRate:
            return .respiratoryRate
        case .vo2Max:
            return .vo2Max
        case .bloodGlucose:
            return .bloodGlucose
        case .bodyTemperature:
            return .bodyTemperature
        case .mindfulMinutes:
            return nil // HKCategoryType - appleMindfulSession
        }
    }
}
