# 타임존 캡처 방식 설명

## 현재 구현

### HealthDataSample 생성 시
```swift
init(
    // ... 다른 파라미터들
    timezone: String? = nil,
    timezoneOffset: Int? = nil
) {
    // ... 다른 필드 초기화
    
    // 현재 디바이스의 타임존 캡처
    let currentTimeZone = TimeZone.current
    self.timezone = timezone ?? currentTimeZone.identifier
    self.timezoneOffset = timezoneOffset ?? (currentTimeZone.secondsFromGMT() / 60)
}
```

### HealthKitManager에서 변환 시
```swift
private func convertToHealthDataSample(_ sample: HKQuantitySample, type: HealthDataType) -> HealthDataSample {
    return HealthDataSample(
        id: UUID(uuidString: sample.uuid.uuidString) ?? UUID(),
        type: type,
        value: value,
        unit: unitString,
        startDate: sample.startDate,
        endDate: sample.endDate,
        sourceBundle: sample.sourceRevision.source.bundleIdentifier,
        metadata: metadata,
        isSynced: false,
        createdAt: Date()
        // timezone, timezoneOffset 파라미터를 전달하지 않음
        // → init에서 TimeZone.current 사용
    )
}
```

## 타임존 캡처 시점

### 시나리오 1: 실시간 동기화
```
서울 (UTC+9)에서 걸음 수 측정
  → HealthKit에 저장
  → 즉시 앱이 조회
  → TimeZone.current = "Asia/Seoul"
  → ✅ 정확한 타임존 캡처
```

### 시나리오 2: 나중에 동기화
```
서울 (UTC+9)에서 걸음 수 측정
  → HealthKit에 저장
  → 뉴욕 (UTC-5)으로 이동
  → 앱이 조회
  → TimeZone.current = "America/New_York"
  → ❌ 잘못된 타임존 캡처
```

## 문제점

### HealthKit의 제한
- HealthKit은 샘플에 타임존 정보를 저장하지 않음
- `HKSample.metadata`에도 타임존 정보 없음
- `startDate`와 `endDate`는 항상 UTC

### 현재 구현의 한계
```swift
// 샘플 측정 시점: 서울 (2024-01-15 10:00 KST)
// HealthKit 저장: startDate = 2024-01-15 01:00:00 UTC

// 나중에 뉴욕에서 조회
let sample = try await healthKitManager.fetchHealthData(...)
// TimeZone.current = "America/New_York"
// ❌ 잘못된 타임존이 샘플에 할당됨
```

## 해결 방법

### 옵션 1: 현재 구현 유지 (권장)
**가정**: 대부분의 사용자는 실시간 또는 같은 타임존에서 동기화

**장점**:
- 구현 간단
- 대부분의 경우 정확
- 추가 저장소 불필요

**단점**:
- 여행 후 동기화 시 부정확

**적용 시나리오**:
- 자동 동기화 활성화 (실시간 또는 시간별)
- 대부분의 사용자가 한 지역에 거주

### 옵션 2: 로컬 저장소에 타임존 캡처
**방법**: HealthKit 샘플 조회 시 즉시 타임존 저장

```swift
// HealthKitManager에서
func fetchHealthData(...) async throws -> [HealthDataSample] {
    let samples = try await // HealthKit 조회
    
    // 조회 시점의 타임존으로 즉시 변환
    let currentTimezone = TimeZone.current.identifier
    let currentOffset = TimeZone.current.secondsFromGMT() / 60
    
    return samples.map { hkSample in
        convertToHealthDataSample(
            hkSample,
            type: type,
            timezone: currentTimezone,
            timezoneOffset: currentOffset
        )
    }
}
```

**장점**:
- 조회 시점의 타임존 캡처
- 여전히 부정확하지만 명시적

**단점**:
- 여전히 측정 시점의 타임존이 아님

### 옵션 3: CoreData에 타임존 저장
**방법**: HealthKit 샘플을 처음 조회할 때 타임존 저장

```swift
// StorageManager에서
func saveHealthData(_ data: [HealthDataSample], userId: String) async throws {
    for sample in data {
        // 이미 저장된 샘플인지 확인
        if let existing = try? fetchSample(id: sample.id) {
            // 기존 샘플의 타임존 유지
            continue
        }
        
        // 새 샘플: 현재 타임존으로 저장
        // (처음 조회 시점의 타임존)
        save(sample)
    }
}
```

**장점**:
- 처음 조회 시점의 타임존 보존
- 이후 조회 시 타임존 변경 없음

**단점**:
- 여전히 측정 시점의 타임존이 아님
- 복잡도 증가

### 옵션 4: 사용자 위치 기록 (가장 정확)
**방법**: 위치 서비스로 타임존 추적

```swift
// LocationManager 추가
class LocationManager {
    func getCurrentTimezone() -> (String, Int) {
        // 현재 위치 기반 타임존
        let location = locationManager.location
        let timezone = TimeZone(identifier: location.timezone)
        return (timezone.identifier, timezone.secondsFromGMT() / 60)
    }
}

// HealthKit 샘플 조회 시
func fetchHealthData(...) async throws -> [HealthDataSample] {
    let samples = try await // HealthKit 조회
    let (timezone, offset) = locationManager.getCurrentTimezone()
    
    return samples.map { hkSample in
        convertToHealthDataSample(
            hkSample,
            timezone: timezone,
            timezoneOffset: offset
        )
    }
}
```

**장점**:
- 가장 정확한 타임존
- 실제 위치 기반

**단점**:
- 위치 권한 필요
- 배터리 소모
- 프라이버시 우려
- 복잡도 증가

## 권장 사항

### 현재 구현 유지 + 자동 동기화
```swift
// 실시간 동기화 활성화
configManager.saveSyncFrequency(.realtime)

// 또는 시간별 동기화
configManager.saveSyncFrequency(.hourly)
```

**이유**:
1. 대부분의 사용자는 한 타임존에 거주
2. 자동 동기화로 측정 직후 캡처
3. 구현 간단, 성능 우수
4. 추가 권한 불필요

### 여행자를 위한 안내
```
설정 > 동기화 빈도 > 실시간

"여행 중에는 실시간 동기화를 활성화하여 
정확한 타임존 정보를 캡처하세요."
```

## 실제 동작

### 정상 케이스 (90%+)
```
서울에서 측정 → 서울에서 동기화
  → timezone: "Asia/Seoul" ✅

뉴욕에서 측정 → 뉴욕에서 동기화
  → timezone: "America/New_York" ✅
```

### 문제 케이스 (드물음)
```
서울에서 측정 → 뉴욕에서 동기화
  → timezone: "America/New_York" ❌
  
하지만:
- startDate는 여전히 UTC로 정확
- Flink에서 UTC 기준 집계는 정확
- 로컬 시간 집계만 부정확
```

## 결론

현재 구현(`TimeZone.current` 사용)은:
- ✅ 대부분의 경우 정확
- ✅ 구현 간단
- ✅ 성능 우수
- ✅ 추가 권한 불필요
- ⚠️ 여행 후 동기화 시 부정확 (드문 케이스)

**권장**: 현재 구현 유지 + 자동 동기화 활성화 권장

더 정확한 타임존이 필요하면:
- 위치 서비스 추가 (옵션 4)
- 사용자에게 위치 권한 요청
- 배터리 소모 및 프라이버시 트레이드오프 고려
