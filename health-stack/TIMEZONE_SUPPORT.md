# 타임존 지원 추가

## 개요
각 건강 데이터 샘플에 타임존 정보를 추가하여 지역별 정확한 집계를 가능하게 합니다.

## 왜 샘플별 타임존이 필요한가?

### 시나리오: 여행하는 사용자
```
서울 (UTC+9)에서 걸음 수 측정
  → 10:00 AM KST = 01:00 AM UTC

뉴욕 (UTC-5)으로 이동 후 걸음 수 측정
  → 10:00 AM EST = 03:00 PM UTC
```

페이로드 레벨 타임존만 있으면:
- ❌ 모든 샘플이 같은 타임존으로 처리됨
- ❌ 여행 중 데이터가 부정확하게 집계됨

샘플별 타임존이 있으면:
- ✅ 각 샘플이 측정된 실제 타임존 보존
- ✅ 지역별 정확한 주간/월간 집계 가능
- ✅ 사용자의 실제 활동 패턴 반영

## 데이터 구조

### HealthDataSample에 추가된 필드
```swift
struct HealthDataSample: Codable {
    // 기존 필드들...
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    
    // 새로 추가된 필드
    let timezone: String        // "Asia/Seoul", "America/New_York"
    let timezoneOffset: Int     // 분 단위 offset (540 for UTC+9, -300 for UTC-5)
}
```

### JSON 예시
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "type": "stepCount",
  "value": 10000,
  "unit": "count",
  "startDate": "2024-01-15T01:00:00Z",
  "endDate": "2024-01-15T02:00:00Z",
  "timezone": "Asia/Seoul",
  "timezoneOffset": 540,
  "sourceBundle": "com.apple.health",
  "metadata": null,
  "isSynced": false,
  "createdAt": "2024-01-15T01:30:00Z"
}
```

## 타임존 정보

### timezone (String)
- IANA 타임존 식별자
- 예시:
  - `"Asia/Seoul"` - 한국
  - `"America/New_York"` - 미국 동부
  - `"Europe/London"` - 영국
  - `"Asia/Tokyo"` - 일본
  - `"America/Los_Angeles"` - 미국 서부

### timezoneOffset (Int)
- UTC로부터의 오프셋 (분 단위)
- 예시:
  - `540` = UTC+9 (한국, 일본)
  - `-300` = UTC-5 (미국 동부 표준시)
  - `0` = UTC (영국 GMT)
  - `-480` = UTC-8 (미국 서부 표준시)

## Flink에서 활용

### 로컬 시간으로 변환
```sql
-- 샘플의 로컬 시간 계산
SELECT 
    id,
    type,
    value,
    startDate,
    timezone,
    timezoneOffset,
    -- UTC 시간을 로컬 시간으로 변환
    startDate + INTERVAL timezoneOffset MINUTE as localStartDate
FROM health_data
```

### 주간 집계 (사용자의 로컬 시간 기준)
```sql
SELECT 
    userId,
    timezone,
    DATE_TRUNC('week', startDate + INTERVAL timezoneOffset MINUTE) as week,
    SUM(value) as totalSteps
FROM health_data
WHERE type = 'stepCount'
GROUP BY userId, timezone, week
```

### 시간대별 활동 패턴 분석
```sql
SELECT 
    userId,
    timezone,
    EXTRACT(HOUR FROM startDate + INTERVAL timezoneOffset MINUTE) as localHour,
    AVG(value) as avgActivity
FROM health_data
WHERE type = 'stepCount'
GROUP BY userId, timezone, localHour
ORDER BY localHour
```

### 지역별 집계
```sql
SELECT 
    timezone,
    COUNT(DISTINCT userId) as userCount,
    AVG(value) as avgSteps
FROM health_data
WHERE type = 'stepCount'
GROUP BY timezone
```

## 실제 사용 예시

### 예시 1: 서울에서 측정
```json
{
  "startDate": "2024-01-15T01:00:00Z",  // UTC 시간
  "timezone": "Asia/Seoul",
  "timezoneOffset": 540,
  // 로컬 시간: 2024-01-15 10:00:00 KST
}
```

Flink 계산:
```
UTC: 2024-01-15 01:00:00
+ 540분 (9시간) = 2024-01-15 10:00:00 (로컬)
```

### 예시 2: 뉴욕에서 측정
```json
{
  "startDate": "2024-01-15T15:00:00Z",  // UTC 시간
  "timezone": "America/New_York",
  "timezoneOffset": -300,
  // 로컬 시간: 2024-01-15 10:00:00 EST
}
```

Flink 계산:
```
UTC: 2024-01-15 15:00:00
- 300분 (5시간) = 2024-01-15 10:00:00 (로컬)
```

### 예시 3: 여행 중 데이터
```json
[
  {
    "startDate": "2024-01-15T01:00:00Z",
    "timezone": "Asia/Seoul",
    "timezoneOffset": 540,
    "value": 5000
  },
  {
    "startDate": "2024-01-16T15:00:00Z",
    "timezone": "America/New_York",
    "timezoneOffset": -300,
    "value": 7000
  }
]
```

주간 집계 시:
- 첫 번째 샘플: 2024-01-15 10:00 KST (월요일 오전)
- 두 번째 샘플: 2024-01-16 10:00 EST (화요일 오전)
- ✅ 각각 올바른 로컬 날짜로 집계됨

## iOS 구현

### 자동 타임존 캡처
```swift
init(
    // ... 다른 파라미터들
    timezone: String? = nil,
    timezoneOffset: Int? = nil
) {
    // ... 다른 필드 초기화
    
    // 현재 타임존 자동 캡처
    let currentTimeZone = TimeZone.current
    self.timezone = timezone ?? currentTimeZone.identifier
    self.timezoneOffset = timezoneOffset ?? (currentTimeZone.secondsFromGMT() / 60)
}
```

### HealthKit 데이터 변환 시
```swift
func convertToHealthDataSample(_ sample: HKQuantitySample, type: HealthDataType) -> HealthDataSample {
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
        // timezone과 timezoneOffset은 자동으로 현재 타임존으로 설정됨
    )
}
```

## 서머타임 (DST) 처리

### 문제
```
미국 동부: 
- 표준시 (EST): UTC-5
- 서머타임 (EDT): UTC-4
```

### 해결
타임존 식별자(`America/New_York`)와 오프셋을 모두 저장:
- `timezone`: 서머타임 규칙 포함
- `timezoneOffset`: 측정 당시의 실제 오프셋

Flink에서:
```sql
-- 오프셋 사용 (간단, 빠름)
startDate + INTERVAL timezoneOffset MINUTE

-- 또는 타임존 식별자 사용 (정확, 복잡)
CONVERT_TZ(startDate, 'UTC', timezone)
```

## 데이터 크기 영향

### 추가 데이터
- `timezone`: ~20 bytes (평균)
- `timezoneOffset`: 4 bytes (int)
- 총: ~24 bytes per sample

### 100개 샘플 기준
- 추가 크기: ~2.4 KB
- 전체 페이로드 대비: ~1-2% 증가
- ✅ 무시할 수 있는 수준

## 마이그레이션

### 기존 데이터
타임존 정보가 없는 기존 데이터:
```sql
-- 기본값으로 UTC 가정
UPDATE health_data
SET 
    timezone = 'UTC',
    timezoneOffset = 0
WHERE timezone IS NULL
```

또는 사용자 프로필의 타임존 사용:
```sql
UPDATE health_data h
SET 
    timezone = u.timezone,
    timezoneOffset = u.timezoneOffset
FROM users u
WHERE h.userId = u.id
  AND h.timezone IS NULL
```

## 테스트

### 다양한 타임존 테스트
```swift
// 서울
let sample1 = HealthDataSample(
    type: .stepCount,
    value: 10000,
    startDate: Date(),
    endDate: Date()
)
// timezone: "Asia/Seoul", timezoneOffset: 540

// 시뮬레이터에서 타임존 변경 후
// 설정 > 일반 > 날짜 및 시간 > 시간대

// 뉴욕
let sample2 = HealthDataSample(
    type: .stepCount,
    value: 5000,
    startDate: Date(),
    endDate: Date()
)
// timezone: "America/New_York", timezoneOffset: -300
```

## 장점

### 1. 정확한 집계
- ✅ 사용자의 실제 활동 시간 반영
- ✅ 주간/월간 집계가 로컬 시간 기준
- ✅ 여행 중 데이터도 정확하게 처리

### 2. 글로벌 서비스
- ✅ 전 세계 사용자 지원
- ✅ 지역별 비교 분석 가능
- ✅ 타임존별 활동 패턴 분석

### 3. 데이터 품질
- ✅ 컨텍스트 정보 보존
- ✅ 데이터 해석 명확
- ✅ 디버깅 용이

## 결론

샘플별 타임존 정보 추가로:
- ✅ 지역별 정확한 집계 가능
- ✅ 여행하는 사용자 지원
- ✅ Flink에서 로컬 시간 기반 분석 가능
- ✅ 글로벌 서비스 준비 완료

이제 전 세계 어디서든 정확한 건강 데이터 집계가 가능합니다! 🌍
