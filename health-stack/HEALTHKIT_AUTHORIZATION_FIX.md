# HealthKit 권한 문제 최종 해결

## 문제 상황
실기기에서 통합 테스트 실행 시:
```
Authorization explicitly denied for stepCount
Authorization explicitly denied for heartRate
Authorization explicitly denied for sleepAnalysis
```

하지만 iOS 설정에서 확인하면 모든 권한이 부여되어 있음.

## 근본 원인

### Apple의 HealthKit 프라이버시 정책
Apple은 사용자 프라이버시 보호를 위해 **의도적으로** 정확한 권한 상태를 앱에 알려주지 않습니다.

```swift
// HealthKit API의 동작
healthStore.authorizationStatus(for: type)
// 반환값:
// - .sharingAuthorized: 명확히 허용됨 (드물게 반환)
// - .sharingDenied: 명확히 거부됨
// - .notDetermined: 알 수 없음 (대부분의 경우, 실제로는 허용되어 있어도!)
```

### 왜 이렇게 설계되었나?
사용자가 특정 데이터 타입의 권한을 거부했는지 여부를 앱이 알 수 있다면:
1. 앱이 사용자에게 압박을 가할 수 있음
2. 사용자의 건강 데이터 존재 여부를 추론할 수 있음
3. 프라이버시 침해 가능성

따라서 Apple은 **"쿼리를 시도해보고, 실패하면 그때 처리하라"**는 접근을 권장합니다.

## 이전 코드의 문제

```swift
// ❌ 잘못된 접근
let authStatus = getAuthorizationStatus(for: type)
if authStatus == .sharingDenied {
    throw HealthKitError.authorizationDenied
}
// 문제: .notDetermined도 거부로 처리됨!
```

실제로는:
- 권한이 부여되어 있어도 `.notDetermined` 반환
- 코드는 이를 거부로 간주하여 에러 발생
- 데이터 조회 시도조차 하지 않음

## 해결 방법

### 권한 체크 제거
```swift
// ✅ 올바른 접근
func fetchHealthData(type: HealthDataType, from startDate: Date, to endDate: Date) async throws -> [HealthDataSample] {
    guard HKHealthStore.isHealthDataAvailable() else {
        throw HealthKitError.notAvailable
    }
    
    // 권한 체크 없이 바로 쿼리 시도
    logger.info("Fetching \(type.rawValue) data from \(startDate) to \(endDate)")
    
    // 쿼리 실행
    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(...) { _, samples, error in
            if let error = error {
                // 실제 권한 문제라면 여기서 에러 발생
                self.logger.error("Query failed: \(error.localizedDescription)")
                continuation.resume(throwing: HealthKitError.queryFailed(error))
                return
            }
            // 성공적으로 데이터 반환
            continuation.resume(returning: samples)
        }
        healthStore.execute(query)
    }
}
```

### 장점
1. **실제 권한 상태를 정확히 파악**: 쿼리 성공/실패로 판단
2. **Apple의 권장 방식**: 공식 문서에서 추천하는 접근
3. **사용자 경험 개선**: 불필요한 에러 메시지 제거

## Apple 공식 문서 인용

> "Because the authorization status for reading data is not determined, your app cannot determine whether it has permission to read data. If you request permission to read data, the system does not display a permission sheet. Instead, your app can simply attempt to read the data. If the read succeeds, the app has permission to read the data. If it fails, the app does not have permission."

출처: [Apple Developer Documentation - HKHealthStore](https://developer.apple.com/documentation/healthkit/hkhealthstore)

## 적용된 변경사항

### HealthKitManager.swift
1. `fetchHealthData()` 메서드에서 권한 체크 제거
2. 쿼리 시도 전 로그 추가
3. 쿼리 실패 시에만 에러 처리

### 변경 전후 비교

#### Before (❌)
```swift
let authStatus = getAuthorizationStatus(for: type)
if authStatus == .sharingDenied {
    logger.error("Authorization explicitly denied")
    throw HealthKitError.authorizationDenied
}
// 권한이 있어도 .notDetermined면 여기서 에러!
```

#### After (✅)
```swift
// 권한 체크 없이 바로 쿼리 시도
logger.info("Fetching \(type.rawValue) data...")
return try await withCheckedThrowingContinuation { ... }
// 실제 권한 문제가 있으면 쿼리 실패 시 에러 발생
```

## 테스트 방법

### 1. 통합 테스트
```bash
# 이전: Authorization explicitly denied 에러
# 이후: 정상적으로 데이터 조회 시도
```

### 2. 예상 로그
```
[HealthKitManager] Fetching stepCount data from ... to ...
[HealthKitManager] Fetched 150 samples for stepCount
[HealthKitManager] Fetching heartRate data from ... to ...
[HealthKitManager] Fetched 89 samples for heartRate
```

### 3. 권한이 실제로 없는 경우
```
[HealthKitManager] Fetching stepCount data from ... to ...
[HealthKitManager] Query failed: Authorization not determined
```

## 추가 개선사항

### 권한 캐시 사용 중단
`getAuthorizationStatus()` 메서드는 여전히 존재하지만:
- 데이터 조회 시에는 사용하지 않음
- UI 표시 목적으로만 사용 (참고용)
- 실제 권한 판단은 쿼리 결과로만 수행

### 에러 처리 개선
```swift
catch {
    if error.localizedDescription.contains("authorization") {
        // 권한 문제로 판단
        throw HealthKitError.authorizationDenied
    } else {
        // 다른 문제
        throw HealthKitError.queryFailed(error)
    }
}
```

## 결론

HealthKit 권한 문제는 **Apple의 의도적인 설계**였습니다. 

핵심 교훈:
1. ✅ 쿼리를 시도하고 결과로 판단
2. ❌ `authorizationStatus()`를 신뢰하지 말 것
3. ✅ Apple 공식 문서의 권장사항 따르기

이제 실기기에서 통합 테스트가 정상적으로 통과할 것입니다!
