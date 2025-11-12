# 싱크 30% 멈춤 문제 디버깅 가이드

## 문제 재현 방법
1. 앱 실행
2. 메인 화면에서 수동 싱크 시작
3. 진행률이 30%에서 멈춤

## 디버깅 체크리스트

### 1. Xcode 콘솔 로그 확인
싱크 시작 시 다음 로그들이 순서대로 나타나야 합니다:

```
[SyncManager] Starting manual sync
[SyncManager] Sync progress: 5%
[HealthKitManager] Fetched X samples for stepCount
[HealthKitManager] Fetched X samples for heartRate
...
[SyncManager] Fetched X new samples from HealthKit
[SyncManager] Sync progress: 20%
[SyncManager] Saving X new samples to storage
[StorageManager] Saving X health data samples for user ...
[StorageManager] Successfully saved X health data samples
[SyncManager] Sync progress: 30%
[SyncManager] Total unsynced samples: X
[SyncManager] Processing batch at offset 0 with Y samples
[SyncManager] Progress: Y/X samples synced (Z%)
...
[SyncManager] Manual sync completed: X samples synced
[SyncManager] Sync progress: 95%
[SyncManager] Sync progress: 100%
[MainViewModel] Sync completed successfully: X samples
```

### 2. 30%에서 멈추는 경우 확인할 것

#### A. "Total unsynced samples: 0" 로그가 보이는가?
- **YES**: 데이터가 저장되지 않았거나 이미 모두 동기화됨
  - 해결: HealthKit에서 데이터를 가져왔는지 확인
  - 로그에서 "Fetched X new samples from HealthKit" 확인
  - X가 0이면 HealthKit 권한 또는 데이터 문제

- **NO**: 다음 단계로

#### B. "Processing batch at offset 0" 로그가 보이는가?
- **YES**: 배치 처리는 시작됨
  - 게이트웨이 전송 중 에러 확인
  - 네트워크 연결 확인
  - 게이트웨이 URL 및 인증 확인

- **NO**: 배치 처리가 시작되지 않음
  - `getUnsyncedDataCount()` 호출 후 멈춤
  - CoreData 쿼리 문제 가능성
  - 다음 섹션 참조

### 3. CoreData 쿼리 문제 디버깅

#### 수동으로 unsynced 데이터 확인
Xcode에서 LLDB 디버거 사용:

```swift
// 브레이크포인트를 SyncManager.performManualSync()의 
// "let unsyncedCount = try await storageManager.getUnsyncedDataCount()" 
// 다음 줄에 설정

// LLDB에서 실행:
po unsyncedCount
```

#### CoreData 직접 확인
```swift
// 브레이크포인트에서:
po try? await storageManager.fetchUnsyncedData(limit: 10, offset: 0)
```

### 4. 권한 문제 디버깅

#### HealthKit 권한 상태 확인
```swift
// IntegrationTester에서 권한 테스트 실행
// 또는 HealthKitManager에 브레이크포인트 설정:

// fetchHealthData() 메서드의 authStatus 체크 부분
po authStatus
// .sharingAuthorized, .sharingDenied, .notDetermined 중 하나
```

#### iOS 설정에서 확인
1. 설정 > 개인정보 보호 및 보안 > 건강
2. 앱 이름 찾기
3. 모든 데이터 타입이 "읽기" 권한이 있는지 확인

### 5. 네트워크 문제 디버깅

#### 게이트웨이 연결 테스트
```swift
// 설정 화면에서 "Test Connection" 버튼 클릭
// 또는 코드에서:
try await gatewayService.testConnection()
```

#### 네트워크 로그 확인
```
[NetworkClient] Sending POST request to https://...
[NetworkClient] Response status: 200
```

### 6. 메모리 문제 디버깅

#### 메모리 사용량 확인
- Xcode의 Debug Navigator에서 Memory 그래프 확인
- 급격한 메모리 증가가 있는지 확인
- 배치 크기(100)가 너무 큰지 확인

## 일반적인 원인과 해결책

### 원인 1: HealthKit 데이터가 없음
**증상**: "Fetched 0 new samples from HealthKit"
**해결**:
- 건강 앱에서 데이터가 있는지 확인
- 권한이 제대로 부여되었는지 확인
- 날짜 범위 확인 (기본 24시간)

### 원인 2: 데이터가 이미 동기화됨
**증상**: "Total unsynced samples: 0"
**해결**:
- 정상 동작임
- 새 데이터를 생성하거나 기다리기
- 또는 CoreData를 리셋하여 테스트

### 원인 3: CoreData 저장 실패
**증상**: "Fetched X new samples" 후 "Total unsynced samples: 0"
**해결**:
- 저장 에러 로그 확인
- 디스크 공간 확인
- CoreData 모델 마이그레이션 필요 여부 확인

### 원인 4: 게이트웨이 전송 실패
**증상**: "Processing batch" 후 멈춤 또는 재시도
**해결**:
- 게이트웨이 URL 확인
- API 키 확인
- 네트워크 연결 확인
- 게이트웨이 서버 상태 확인

### 원인 5: UI 업데이트 실패
**증상**: 로그는 진행되지만 UI는 30%에 멈춤
**해결**:
- MainViewModel의 syncStatus 업데이트 확인
- @MainActor 어노테이션 확인
- View의 바인딩 확인

## 긴급 디버깅 코드 추가

### SyncManager에 추가 로그 삽입
```swift
// performManualSync() 메서드에 추가:

logger.info("=== SYNC DEBUG START ===")
logger.info("Step 1: Clearing auth cache")
// ... 기존 코드

logger.info("Step 2: Fetching new data")
let newData = try await fetchNewHealthData()
logger.info("Step 2 DONE: Got \(newData.count) samples")

logger.info("Step 3: Saving to storage")
// ... 저장 코드
logger.info("Step 3 DONE")

logger.info("Step 4: Getting unsynced count")
let unsyncedCount = try await storageManager.getUnsyncedDataCount()
logger.info("Step 4 DONE: Count = \(unsyncedCount)")

if unsyncedCount == 0 {
    logger.warning("⚠️ NO UNSYNCED DATA - Exiting early")
    // ... 종료 코드
    return
}

logger.info("Step 5: Starting batch processing")
// ... 배치 처리 코드
logger.info("=== SYNC DEBUG END ===")
```

### StorageManager에 추가 로그 삽입
```swift
// saveHealthData() 메서드에:
logger.info("Saving \(data.count) samples - START")
// ... 저장 로직
logger.info("Saving \(data.count) samples - DONE")

// getUnsyncedDataCount() 메서드에:
logger.info("Counting unsynced data - START")
let count = try context.count(for: fetchRequest)
logger.info("Counting unsynced data - DONE: \(count)")
return count
```

## 테스트 시나리오

### 시나리오 1: 클린 스타트
1. 앱 삭제
2. 재설치
3. 온보딩 완료
4. 게이트웨이 설정
5. 수동 싱크 실행
6. 로그 전체 캡처

### 시나리오 2: 데이터 리셋
1. 설정 > 개발자 옵션 (있다면)
2. CoreData 리셋
3. 수동 싱크 실행
4. 로그 전체 캡처

### 시나리오 3: 통합 테스트
1. 통합 테스트 화면 열기
2. "Run All Tests" 실행
3. 각 테스트 결과 확인
4. 실패한 테스트의 에러 메시지 확인

## 로그 수집 방법

### Xcode 콘솔에서
1. Xcode에서 앱 실행
2. 콘솔 창 열기 (Cmd + Shift + C)
3. 필터에 "SyncManager" 입력
4. 싱크 시작
5. 모든 로그 복사

### 디바이스 콘솔에서
1. Mac에 디바이스 연결
2. Console.app 열기
3. 디바이스 선택
4. 필터에 앱 이름 입력
5. 싱크 시작
6. 로그 저장

## 다음 단계

로그를 수집한 후:
1. 어느 단계에서 멈추는지 확인
2. 해당 단계의 에러 메시지 확인
3. 위의 해결책 적용
4. 여전히 문제가 있으면 로그와 함께 보고
