# 실기기 테스트 문제 해결 (v2)

## 발견된 문제

### 1. 헬스킷 권한 오류 (실제로는 권한이 부여됨)
**증상**: 통합 테스트에서 헬스킷 권한이 없다고 표시되지만, 실제로는 권한이 부여되어 있음

**원인**: 
- `HealthKitManager`가 권한 상태를 5분간 캐시하고 있음
- 권한이 부여된 직후에도 캐시된 이전 상태를 사용
- HealthKit API의 특성상 `.notDetermined`를 반환할 수 있음 (프라이버시 보호)

**해결 방법**:
1. 통합 테스트 시작 시 권한 캐시를 명시적으로 클리어
2. 권한 요청 후 0.5초 대기하여 시스템이 권한 상태를 업데이트할 시간 제공
3. 데이터 조회 시 `.sharingDenied`만 명시적으로 거부하고, `.notDetermined`는 쿼리 시도
4. 쿼리 실패 시 실제 에러 메시지를 로깅하여 디버깅 용이

### 2. 데이터 싱크가 30%에서 멈춤 ⭐ 주요 수정
**증상**: 싱크 진행률이 30%에서 더 이상 진행되지 않음

**원인**:
1. **진행률 업데이트 로직 문제**
   - MainViewModel이 `.syncing` 케이스의 progress 값을 무시
   - UI가 업데이트되지 않음

2. **CoreData 커밋 타이밍 문제**
   - 데이터 저장 직후 조회 시 아직 커밋되지 않을 수 있음
   - `getUnsyncedDataCount()`가 0을 반환

3. **배치 처리 로직 문제**
   - offset 계산 오류
   - 로그 부족으로 디버깅 어려움

4. **로그 부족**
   - 어느 단계에서 멈추는지 파악 불가

**해결 방법**:
1. **MainViewModel 수정**
   - `.syncing(let progress)` 케이스에서 progress 값 사용
   - 각 상태 변경 시 로그 추가

2. **CoreData 커밋 대기**
   - 저장 후 0.1초 대기하여 커밋 완료 보장
   - 조회 전 로그로 확인

3. **배치 처리 개선**
   - 각 배치마다 상세한 로그 추가
   - 진행 상황을 백분율로 표시
   - 무한 루프 방지 안전장치 추가

4. **상세한 로그 추가**
   - 각 단계별 시작/완료 로그
   - 데이터 개수 및 진행률 로그
   - 에러 발생 시 컨텍스트 정보

## 적용된 변경사항

### IntegrationTester.swift
```swift
// 권한 테스트 전 캐시 클리어
if let healthKitManager = healthKitManager as? HealthKitManager {
    healthKitManager.clearAuthorizationCache()
}

// 권한 요청 후 대기
try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
```

### HealthKitManager.swift
```swift
// 권한 체크 로직 개선
if authStatus == .sharingDenied {
    logger.error("Authorization explicitly denied for \(type.rawValue)")
    throw HealthKitError.authorizationDenied
}
// .notDetermined는 쿼리 시도 (HealthKit 프라이버시 정책)

// 상세한 로깅 추가
self.logger.info("Fetched \(samples.count) samples for \(type.rawValue)")
```

### SyncManager.swift
```swift
// 싱크 시작 시 권한 캐시 클리어
if let healthKitManager = healthKitManager as? HealthKitManager {
    healthKitManager.clearAuthorizationCache()
}

// 세밀한 진행률 업데이트
updateStatus(.syncing(progress: 0.05))  // 초기화
updateStatus(.syncing(progress: 0.2))   // 데이터 조회 완료
updateStatus(.syncing(progress: 0.3))   // 저장 완료
// ... 전송 중 30% - 90%
updateStatus(.syncing(progress: 0.95))  // 정리 작업
updateStatus(.syncing(progress: 1.0))   // 완료

// 배치 offset 계산 수정
offset += batchData.count  // 실제 배치 크기 사용

// 상세한 로그 추가
logger.info("Progress: \(totalSynced)/\(unsyncedCount) samples synced (\(Int((Double(totalSynced)/Double(unsyncedCount)) * 100))%)")
```

## 테스트 방법

### 1. 헬스킷 권한 테스트
1. 앱 삭제 후 재설치
2. 온보딩에서 헬스킷 권한 부여
3. 통합 테스트 실행
4. "HealthKit Authorization" 테스트가 통과하는지 확인
5. 각 데이터 타입 추출 테스트가 통과하는지 확인

### 2. 싱크 진행률 테스트
1. 설정에서 게이트웨이 구성
2. 메인 화면에서 수동 싱크 실행
3. 진행률이 0% → 5% → 20% → 30% → ... → 100%로 진행되는지 확인
4. 로그에서 각 단계별 메시지 확인:
   - "Fetched X new samples from HealthKit"
   - "Saving X new samples to storage"
   - "Total unsynced samples: X"
   - "Processing batch at offset X with Y samples"
   - "Progress: X/Y samples synced (Z%)"
   - "Manual sync completed: X samples synced"

### 3. 엣지 케이스 테스트
- 데이터가 없을 때: 진행률이 100%로 완료되는지 확인
- 네트워크 오류 시: 재시도 로직이 작동하는지 확인
- 대용량 데이터: 배치 처리가 정상 작동하는지 확인

## 추가 개선 사항

### 권한 관련
- HealthKit의 프라이버시 정책상 `.notDetermined`가 반환될 수 있음을 고려
- 실제 쿼리 실패 시에만 에러 처리
- 권한 캐시를 중요한 작업 전에 클리어

### 진행률 관련
- 각 단계별 진행률을 명확히 정의
- 데이터가 없는 경우도 100% 완료로 처리
- 실제 배치 크기를 사용하여 정확한 offset 계산

### 로깅 관련
- 각 단계별 상세한 로그 추가
- 에러 발생 시 컨텍스트 정보 포함
- 진행 상황을 백분율로 표시

## 알려진 제한사항

1. **HealthKit 권한 상태**: iOS의 프라이버시 정책상 정확한 권한 상태를 알 수 없을 수 있음
2. **권한 캐시**: 5분 타임아웃이 있지만, 중요한 작업 전에는 명시적으로 클리어
3. **배치 크기**: 메모리 최적화를 위해 100개씩 처리하지만, 대용량 데이터는 시간이 걸릴 수 있음

## 문제 발생 시 체크리스트

- [ ] 앱이 최신 버전으로 빌드되었는가?
- [ ] 헬스킷 권한이 iOS 설정에서 실제로 부여되었는가?
- [ ] 게이트웨이가 올바르게 구성되었는가?
- [ ] 네트워크 연결이 정상인가?
- [ ] Xcode 콘솔에서 로그를 확인했는가?
- [ ] 통합 테스트 결과를 확인했는가?
