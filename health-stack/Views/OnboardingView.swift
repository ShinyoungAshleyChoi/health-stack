//
//  OnboardingView.swift
//  health-stack
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Binding var isOnboardingComplete: Bool
    
    private let configurationManager: ConfigurationManagerProtocol
    private let healthKitManager: HealthKitManager
    
    init(
        isOnboardingComplete: Binding<Bool>,
        configurationManager: ConfigurationManagerProtocol,
        healthKitManager: HealthKitManager
    ) {
        _isOnboardingComplete = isOnboardingComplete
        self.configurationManager = configurationManager
        self.healthKitManager = healthKitManager
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            configurationManager: configurationManager,
            healthKitManager: healthKitManager
        ))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)
            
            VStack(spacing: 0) {
                // Content
                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        WelcomeScreen(viewModel: viewModel)
                            .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.welcomeScreen)
                    case .healthKitPermission:
                        HealthKitPermissionScreen(viewModel: viewModel)
                            .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.permissionScreen)
                    case .dataTypeSelection:
                        DataTypeSelectionScreen(viewModel: viewModel)
                            .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.dataTypeScreen)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
                // Custom Page Indicator
                HStack(spacing: 8) {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        Circle()
                            .fill(viewModel.currentStep == step ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.bottom, 20)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(viewModel.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
                .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.pageIndicator)
            }
        }
        .errorAlert(error: $viewModel.errorInfo) {
            viewModel.requestHealthKitPermission()
        }
        .onChange(of: viewModel.isComplete) { isComplete in
            if isComplete {
                HapticFeedback.success.generate()
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isOnboardingComplete = true
    }
}

// MARK: - Onboarding Step Enum

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case healthKitPermission = 1
    case dataTypeSelection = 2
}

// MARK: - Welcome Screen

struct WelcomeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.white)
            
            // Title
            Text("Welcome to Health Sync")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text("Securely sync your health data from HealthKit to your personal gateway")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Get Started Button
            Button(action: {
                HapticFeedback.medium.generate()
                viewModel.moveToNextStep()
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.getStartedButton)
            .accessibilityHint("Begins the onboarding process")
        }
    }
}

// MARK: - HealthKit Permission Screen

struct HealthKitPermissionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "heart.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
            
            // Title
            Text("HealthKit Access")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            // Description
            VStack(alignment: .leading, spacing: 16) {
                PermissionItem(
                    icon: "figure.walk",
                    text: "Activity data like steps and exercise"
                )
                PermissionItem(
                    icon: "heart.fill",
                    text: "Cardiovascular data like heart rate"
                )
                PermissionItem(
                    icon: "bed.double.fill",
                    text: "Sleep analysis and patterns"
                )
                PermissionItem(
                    icon: "fork.knife",
                    text: "Nutrition and dietary information"
                )
            }
            .padding(.horizontal, 32)
            
            Text("We need your permission to read health data from HealthKit. You can customize which data types to sync in the next step.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 16) {
                Button(action: {
                    HapticFeedback.medium.generate()
                    viewModel.requestHealthKitPermission()
                }) {
                    HStack {
                        if viewModel.isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .accessibilityLabel("Requesting permission")
                        }
                        Text(viewModel.isRequestingPermission ? "Requesting..." : "Grant Permission")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isRequestingPermission)
                .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.grantPermissionButton)
                .accessibilityLabel(viewModel.isRequestingPermission ? "Requesting permission" : "Grant permission")
                .accessibilityHint("Requests access to HealthKit data")
                
                Button(action: {
                    HapticFeedback.light.generate()
                    viewModel.skipHealthKitPermission()
                }) {
                    Text("Skip for Now")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.skipButton)
                .accessibilityHint("Skips permission request and continues to next step")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct PermissionItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Data Type Selection Screen

struct DataTypeSelectionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icon
                Image(systemName: "checklist")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .padding(.top, 48)
                
                // Title
                Text("Select Data Types")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Description
                Text("Choose which health data types you want to sync")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Category List
                VStack(spacing: 16) {
                    ForEach(HealthDataCategory.allCases, id: \.self) { category in
                        CategoryToggleCard(
                            category: category,
                            isEnabled: viewModel.isCategoryEnabled(category),
                            onToggle: {
                                viewModel.toggleCategory(category)
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                // Finish Button
                Button(action: {
                    HapticFeedback.success.generate()
                    viewModel.completeOnboarding()
                }) {
                    Text("Finish Setup")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .accessibilityIdentifier(AccessibilityIdentifiers.OnboardingView.finishButton)
                .accessibilityHint("Completes onboarding and opens the main app")
            }
        }
    }
}

struct CategoryToggleCard: View {
    let category: HealthDataCategory
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection.generate()
            onToggle()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(category.dataTypes.count) data types")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isEnabled ? .green : .white.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.displayName), \(category.dataTypes.count) data types")
        .accessibilityValue(isEnabled ? "enabled" : "disabled")
        .accessibilityHint("Double tap to toggle this category")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("\(AccessibilityIdentifiers.OnboardingView.categoryCard)_\(category.rawValue)")
    }
}

// MARK: - Custom Text Field Style

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
            .foregroundColor(.black)
    }
}
