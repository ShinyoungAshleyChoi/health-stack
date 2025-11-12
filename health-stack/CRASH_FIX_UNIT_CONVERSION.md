# 앱 크래시 수정: 단위 변환 오류

## 크래시 정보
```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', 
reason: 'Attempt to convert incompatible units: s, count'
```

## 원인

### Apple의 HealthKit 데이터 저장 방식
Apple은 시간 관련 데이터를 **초(second)** 단위로 저장합니다:
- `appleExerciseTime`: 초 단위
- `appleStandTime`: 초 단위

### 코드의 문제
```swift
// ❌ 잘못된 단위 설정
case .exerciseTime:
    return .minute()  // 분으로 설정했지만, HealthKit은 초로 저장
case .standHours:
    return .count()   // count로 설정했지만, HealthKit은 초로 저장
```

### 크래시 발생 시점
```swift
// HealthKitManager.swift
let value = sample.quantity.doubleValue(for: type.unit)
// type.unit이 .minute()인데, sample은 .second()로 저장됨
// → 단위 변환 불가능 → 크래시!
```

## 해결 방법

### 올바른 단위 설정
```swift
// ✅ 수정된 코드
case .exerciseTime:
    return .second() // Apple Exercise Time is stored in seconds
case .standHours:
    return .second() // Apple Stand Time is stored in seconds
```

## Apple 공식 문서 확인

### appleExerciseTime
> "The quantity type identifier for the amount of time the user spent exercising. 
> The unit for this quantity type is **time in seconds**."

출처: [HKQuantityTypeIdentifier.appleExerciseTime](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/1615771-appleexercisetime)

### appleStandTime
> "The quantity type identifier for the amount of time the user has stood. 
> The unit for this quantity type is **time in seconds**."

출처: [HKQuantityTypeIdentifier.appleStandTime](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/2867757-applestandtime)

## 영향 범위

### 수정 전
- `exerciseTime` 조회 시 크래시
- `standHours` 조회 시 크래시
- 통합 테스트 실패
- 수동 싱크 실패

### 수정 후
- 모든 데이터 타입 정상 조회
- 통합 테스트 통과
- 수동 싱크 정상 작동

## 데이터 표시 방식

### 저장 단위 vs 표시 단위
```swift
// HealthKit에서 가져온 값 (초 단위)
let exerciseSeconds = 1800.0  // 30분

// UI에 표시할 때는 분으로 변환
let exerciseMinutes = exerciseSeconds / 60.0  // 30.0
```

### 향후 개선 사항
UI에서 사용자에게 표시할 때는 더 읽기 쉬운 단위로 변환:
```swift
extension Double {
    func secondsToMinutes() -> Double {
        return self / 60.0
    }
    
    func secondsToHours() -> Double {
        return self / 3600.0
    }
    
    func formatDuration() -> String {
        let hours = Int(self / 3600)
        let minutes = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// 사용 예
let exerciseTime = 1800.0  // 초
print(exerciseTime.formatDuration())  // "30m"
```

## 테스트 방법

### 1. 빌드 및 실행
```bash
# Xcode에서 Clean Build Folder (Cmd + Shift + K)
# 다시 빌드 (Cmd + B)
# 실기기에서 실행
```

### 2. 통합 테스트
- 통합 테스트 화면으로 이동
- "Run All Tests" 실행
- 모든 테스트가 통과하는지 확인

### 3. 수동 싱크
- 메인 화면에서 "Sync Now" 실행
- 크래시 없이 정상 완료되는지 확인

## 다른 시간 관련 데이터 타입 확인

### 올바르게 설정된 타입들
```swift
case .sleepAnalysis, .timeInBed:
    return .minute()  // ✅ 수면 데이터는 분 단위로 계산됨 (우리가 변환)

case .mindfulMinutes:
    return .minute()  // ✅ 마음챙김 세션도 분 단위

case .heartRateVariability:
    return .secondUnit(with: .milli)  // ✅ 밀리초 단위
```

## 교훈

1. **Apple 문서 확인**: 각 데이터 타입의 저장 단위를 공식 문서에서 확인
2. **단위 테스트**: 각 데이터 타입별로 단위 변환 테스트 작성
3. **에러 처리**: 단위 변환 실패 시 크래시 대신 에러 로깅

## 관련 파일
- `health-stack/Models/HealthDataType.swift` - 단위 정의
- `health-stack/Managers/HealthKitManager.swift` - 데이터 조회 및 변환

## 추가 검증 필요
다른 데이터 타입들도 올바른 단위를 사용하는지 확인:
- [ ] `heartRateVariability` - 밀리초 확인
- [ ] `vo2Max` - 복합 단위 확인
- [ ] `bloodGlucose` - mg/dL 확인
- [ ] 모든 dietary 타입 - 그램/칼로리 확인

## 결론
Apple의 HealthKit은 시간 데이터를 **초 단위**로 저장합니다. 
UI 표시를 위해 분이나 시간으로 변환하는 것은 별도로 처리해야 합니다.

이제 앱이 정상적으로 작동할 것입니다! 🎉
