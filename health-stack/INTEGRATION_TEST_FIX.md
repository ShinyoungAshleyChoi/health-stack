# 통합 테스트 설정 복원 문제 수정

## 문제 상황
통합 테스트 실행 후 게이트웨이 설정이 잘못된 상태로 남아있음:
```
Gateway service configured with URL: https://invalid-gateway-that-does-not-exist.example.com
```

## 원인

### IntegrationTester의 문제
```swift
// ❌ 이전 코드
private func testInvalidGateway() async -> TestResult {
    // 잘못된 게이트웨이 설정
    let invalidConfig = GatewayConfig(
        baseURL: "https://invalid-gateway-that-does-not-exist.example.com",
        port: 9999,
        apiKey: "invalid-key",
        username: nil,
        password: nil
    )
    
    try configManager.saveGatewayConfig(invalidConfig)
    // ... 테스트 수행
    
    // ❌ 원래 설정으로 복원하지 않음!
}
```

### 영향
1. 통합 테스트 실행
2. 에러 시나리오 테스트에서 잘못된 게이트웨이 설정
3. 테스트 완료 후에도 잘못된 설정 유지
4. 수동 싱크 시도 시 잘못된 게이트웨이로 전송 시도
5. 연결 실패

## 해결 방법

### 1. 원래 설정 저장 및 복원
```swift
// ✅ 수정된 코드
private func testInvalidGateway() async -> TestResult {
    // 원래 설정 저장
    let originalConfig = try? configManager.getGatewayConfig()
    
    // 잘못된 게이트웨이 설정
    let invalidConfig = GatewayConfig(
        baseURL: "https://invalid-gateway-that-does-not-exist.example.com",
        port: 9999,
        apiKey: "invalid-key",
        username: nil,
        password: nil
    )
    
    // 테스트 수행
    let result: TestResult
    do {
        try configManager.saveGatewayConfig(invalidConfig)
        try gatewayService.configure(config: invalidConfig)
        let connected = try await gatewayService.testConnection()
        
        result = TestResult(
            name: "Invalid Gateway Handling",
            category: .errorHandling,
            status: connected ? .failed : .passed,
            message: connected ? "Invalid gateway accepted" : "Invalid gateway correctly rejected",
            timestamp: Date(),
            duration: Date().timeIntervalSince(start)
        )
    } catch {
        result = TestResult(
            name: "Invalid Gateway Handling",
            category: .errorHandling,
            status: .passed,
            message: "Invalid gateway correctly rejected: \(error.localizedDescription)",
            timestamp: Date(),
            duration: Date().timeIntervalSince(start)
        )
    }
    
    // ✅ 원래 설정으로 복원
    if let originalConfig = originalConfig {
        try? configManager.saveGatewayConfig(originalConfig)
        try? gatewayService.configure(config: originalConfig)
    }
    
    return result
}
```

### 2. HTTPS 테스트도 동일하게 수정
```swift
// ✅ 수정된 코드
func testHTTPSEnforcement() async {
    currentTest = "Testing HTTPS enforcement..."
    
    // 원래 설정 저장
    let originalConfig = try? configManager.getGatewayConfig()
    
    let result = await testHTTPRejection()
    testResults.append(result)
    
    let httpsResult = await testHTTPSAcceptance()
    testResults.append(httpsResult)
    
    // ✅ 원래 설정으로 복원
    if let originalConfig = originalConfig {
        try? configManager.saveGatewayConfig(originalConfig)
        try? gatewayService.configure(config: originalConfig)
    }
}
```

## 테스트 패턴

### 설정 변경이 필요한 테스트의 올바른 패턴
```swift
func testWithConfigChange() async -> TestResult {
    // 1. 원래 설정 저장
    let originalConfig = try? configManager.getGatewayConfig()
    
    // 2. 테스트용 설정 적용
    let testConfig = GatewayConfig(...)
    try? configManager.saveGatewayConfig(testConfig)
    
    // 3. 테스트 수행
    let result = performTest()
    
    // 4. 원래 설정 복원 (항상!)
    if let originalConfig = originalConfig {
        try? configManager.saveGatewayConfig(originalConfig)
        try? gatewayService.configure(config: originalConfig)
    }
    
    return result
}
```

## 기본 설정 동작

### 통합 테스트 전
```
게이트웨이 설정: https://192.168.45.185:3000 (기본값)
```

### 통합 테스트 중
```
1. HTTP 테스트: http://insecure.example.com (임시)
2. HTTPS 테스트: https://secure.example.com (임시)
3. 에러 테스트: https://invalid-gateway... (임시)
```

### 통합 테스트 후
```
게이트웨이 설정: https://192.168.45.185:3000 (복원됨!)
```

## 검증 방법

### 1. 통합 테스트 실행 전
```swift
// Xcode 콘솔에서 확인
[ConfigurationManager] Gateway config: https://192.168.45.185:3000
```

### 2. 통합 테스트 실행
```swift
// 테스트 중 임시 설정 사용
[IntegrationTester] Testing HTTPS enforcement...
[GatewayService] Gateway service configured with URL: http://insecure.example.com
[IntegrationTester] Testing error scenarios...
[GatewayService] Gateway service configured with URL: https://invalid-gateway...
```

### 3. 통합 테스트 완료 후
```swift
// 원래 설정으로 복원됨
[ConfigurationManager] Gateway config: https://192.168.45.185:3000
```

### 4. 수동 싱크 테스트
```swift
// 기본 설정으로 정상 작동
[SyncManager] Starting manual sync
[GatewayService] Gateway service configured with URL: https://192.168.45.185:3000
[SyncManager] Sending 100 samples in 1 batches to gateway
```

## 추가 개선사항

### 테스트 격리 (Test Isolation)
각 테스트가 독립적으로 실행되도록:

```swift
class IntegrationTester {
    // 테스트 시작 시 설정 저장
    private var savedConfig: GatewayConfig?
    
    func runAllTests() async {
        isRunning = true
        testResults.removeAll()
        
        // 테스트 시작 전 설정 저장
        savedConfig = try? configManager.getGatewayConfig()
        
        // 모든 테스트 실행
        await testHealthKitDataExtraction()
        await testStoragePersistence()
        await testHTTPSEnforcement()
        await testSyncFlow()
        await testErrorScenarios()
        await testPermissionFlows()
        await testDataRecovery()
        
        // 테스트 완료 후 설정 복원
        if let savedConfig = savedConfig {
            try? configManager.saveGatewayConfig(savedConfig)
            try? gatewayService.configure(config: savedConfig)
        }
        
        isRunning = false
        currentTest = "All tests completed"
    }
}
```

### 설정 복원 보장
```swift
func testWithConfigChange() async -> TestResult {
    let originalConfig = try? configManager.getGatewayConfig()
    
    defer {
        // defer를 사용하여 에러가 발생해도 복원 보장
        if let originalConfig = originalConfig {
            try? configManager.saveGatewayConfig(originalConfig)
            try? gatewayService.configure(config: originalConfig)
        }
    }
    
    // 테스트 수행
    let testConfig = GatewayConfig(...)
    try? configManager.saveGatewayConfig(testConfig)
    
    return performTest()
}
```

## 문제 해결

### 여전히 잘못된 설정이 남아있는 경우

#### 방법 1: 앱 재시작
1. 앱 종료
2. 앱 재실행
3. 기본 설정 자동 로드

#### 방법 2: 설정 화면에서 수동 복원
1. 설정 화면 이동
2. Gateway Configuration 섹션
3. Base URL: `https://192.168.45.185`
4. Port: `3000`
5. Save 버튼 클릭

#### 방법 3: 캐시 클리어
```swift
// ConfigurationManager에서
configManager.clearConfigurationCache()
```

#### 방법 4: UserDefaults 초기화 (최후의 수단)
```swift
// 모든 설정 삭제
UserDefaults.standard.removeObject(forKey: "gateway_base_url")
UserDefaults.standard.removeObject(forKey: "gateway_port")
// 앱 재시작 후 기본 설정 사용
```

## 테스트 체크리스트

통합 테스트 실행 후 확인:
- [ ] 게이트웨이 URL이 기본값으로 복원됨
- [ ] 수동 싱크가 정상 작동함
- [ ] 연결 테스트가 성공함
- [ ] 로그에 올바른 URL이 표시됨

## 관련 파일
- `health-stack/Utilities/IntegrationTester.swift` - 테스트 로직
- `health-stack/Managers/ConfigurationManager.swift` - 설정 관리
- `health-stack/Services/GatewayService.swift` - 게이트웨이 통신

## 결론

통합 테스트는 이제 다음을 보장합니다:
1. ✅ 테스트 중 임시 설정 사용
2. ✅ 테스트 완료 후 원래 설정 복원
3. ✅ 수동 싱크가 정상 작동
4. ✅ 기본 게이트웨이 주소 유지

이제 통합 테스트를 실행해도 게이트웨이 설정이 망가지지 않습니다! 🎉
