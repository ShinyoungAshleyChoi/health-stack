//
//  HealthDataCategory.swift
//  health-stack
//

import Foundation

enum HealthDataCategory: String, CaseIterable {
    case activity
    case cardiovascular
    case sleep
    case nutrition
    case bodyMeasurements
    case respiratory
    case other
    
    var displayName: String {
        switch self {
        case .activity:
            return "Activity & Fitness"
        case .cardiovascular:
            return "Cardiovascular"
        case .sleep:
            return "Sleep"
        case .nutrition:
            return "Nutrition"
        case .bodyMeasurements:
            return "Body Measurements"
        case .respiratory:
            return "Respiratory"
        case .other:
            return "Other"
        }
    }
    
    var dataTypes: [HealthDataType] {
        switch self {
        case .activity:
            return [
                .stepCount,
                .distanceWalkingRunning,
                .flightsClimbed,
                .activeEnergyBurned,
                .basalEnergyBurned,
                .exerciseTime,
                .standHours
            ]
        case .cardiovascular:
            return [
                .heartRate,
                .restingHeartRate,
                .heartRateVariability,
                .bloodPressureSystolic,
                .bloodPressureDiastolic,
                .oxygenSaturation
            ]
        case .sleep:
            return [
                .sleepAnalysis,
                .timeInBed
            ]
        case .nutrition:
            return [
                .dietaryEnergy,
                .dietaryEnergyConsumed,
                .dietaryProtein,
                .dietaryCarbohydrates,
                .dietaryFat,
                .dietaryFiber,
                .dietarySugar,
                .dietaryWater
            ]
        case .bodyMeasurements:
            return [
                .height,
                .bodyMass,
                .bodyMassIndex,
                .bodyFatPercentage,
                .leanBodyMass,
                .waistCircumference
            ]
        case .respiratory:
            return [
                .respiratoryRate,
                .vo2Max
            ]
        case .other:
            return [
                .bloodGlucose,
                .bodyTemperature,
                .mindfulMinutes
            ]
        }
    }
}
