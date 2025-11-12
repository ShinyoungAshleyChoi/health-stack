# 실기기 테스트 빠른 체크리스트

## 테스트 전 준비
- [ ] Xcode에서 실기기로 빌드 및 실행
- [ ] Xcode 콘솔 창 열기 (Cmd + Shift + C)
- [ ] 콘솔 필터에 "SyncManager" 입력

## 1. 헬스킷 권한 테스트

### 실행
1. 앱 실행
2. 통합 테스트 화면으로 이동
3. "Run All Tests" 버튼 클릭
4. "HealthKit Authorization" 테스트 결과 확인

### 예상 결과
- ✅ "HealthKit Authorization" - PASSED
- ✅ "Extract stepCount" - PASSED (또는 WARNING if no data)
- ✅ "Extract heartRate" - PASSED (또는 WARNING if no data)

### 실패 시 확인
```
콘솔에서 찾아볼 로그:
[HealthKitManager] Authorization explicitly denied for ...
```

**해결**: iOS 설정 > 개인정보 보호 > 건강 > 앱 이름 > 모든 항목 "읽기" 활성화

## 2. 싱크 진행률 테스트

### 실행
1. 메인 화면으로 이동
2. "Sync Now" 버튼 클릭
3. 진행률 바 관찰
4. Xcode 콘솔 로그 관찰

### 예상 로그 순서
```
[SyncManager] Starting manual sync
[SyncManager] Sync progress: 5%
[HealthKitManager] Fetched X samples for stepCount
[SyncManager] Fetched X new samples from HealthKit
[SyncManager] Sync progress: 20%
[SyncManager] Saving X new samples to storage
[StorageManager] Successfully saved X health data samples
[SyncManager] Sync progress: 30%
[SyncManager] Fetching unsynced data count...
[SyncManager] Unsynced data count: X
[SyncManager] Starting batch processing: Y batches
[SyncManager] === Batch 1/Y - Offset: 0 ===
[SyncManager] ✓ Fetched Z samples
[SyncManager] Progress updated to 30%
[SyncManager] Sending batch to gateway...
[SyncManager] ✓ Sent Z samples successfully
[SyncManager] === Batch Complete: Z/X samples synced (N%) ===
...
[SyncManager] Batch processing complete: X total samples synced
[SyncManager] Manual sync completed: X samples synced
[MainViewModel] Sync completed successfully: X samples
```

### 30%에서 멈추는 경우

#### 케이스 A: "Unsynced data count: 0" 로그가 보임
**의미**: 동기화할 데이터가 없음

**확인**:
```
위쪽 로그에서:
[SyncManager] Fetched X new samples from HealthKit
```
- X = 0 이면: HealthKit에 데이터가 없거나 권한 문제
- X > 0 이면: 저장은 되었지만 조회가 안 됨 (CoreData 문제)

**해결**:
- 건강 앱에서 데이터 확인
- 또는 앱을 삭제하고 재설치하여 CoreData 리셋

#### 케이스 B: "Starting batch processing" 로그가 안 보임
**의미**: 배치 처리가 시작되지 않음

**확인**:
```
마지막 로그:
[SyncManager] Unsynced data count: X
```
- 이 다음에 아무것도 없으면 코드 실행이 멈춤

**해결**:
- 앱 재시작
- 로그 전체를 캡처하여 에러 확인

#### 케이스 C: "Sending batch to gateway..." 후 멈춤
**의미**: 네트워크 또는 게이트웨이 문제

**확인**:
```
[NetworkClient] 관련 로그 찾기
```

**해결**:
- 설정에서 "Test Connection" 실행
- 게이트웨이 URL 및 API 키 확인
- 네트워크 연결 확인

#### 케이스 D: 로그는 진행되는데 UI는 30%
**의미**: UI 업데이트 문제

**확인**:
```
[MainViewModel] Sync progress: X%
```
- 이 로그가 계속 나오는지 확인

**해결**:
- 앱 재시작
- 메모리 부족 가능성 확인

## 3. 빠른 디버깅 명령어

### Xcode 콘솔에서 필터 사용
```
# 싱크 관련 로그만 보기
SyncManager

# 에러만 보기
error

# 특정 단계만 보기
Batch

# 진행률만 보기
progress
```

### 로그 저장
1. 콘솔에서 우클릭
2. "Save Console Output..."
3. 파일로 저장하여 분석

## 4. 성공 기준

### 통합 테스트
- [ ] 모든 테스트 PASSED 또는 WARNING (데이터 없음은 정상)
- [ ] FAILED 테스트 없음

### 수동 싱크
- [ ] 진행률이 0% → 100%까지 진행
- [ ] "Sync completed successfully" 메시지 표시
- [ ] 에러 없음

### 로그
- [ ] 모든 단계의 로그가 순서대로 출력
- [ ] "ERROR" 로그 없음
- [ ] "⚠️" 경고가 있다면 이유 파악

## 5. 문제 보고 시 포함할 정보

1. **증상**
   - 진행률이 멈춘 지점 (예: 30%)
   - UI에 표시된 메시지

2. **로그**
   - Xcode 콘솔 전체 로그 (또는 저장된 파일)
   - 특히 마지막 10-20줄

3. **환경**
   - iOS 버전
   - 디바이스 모델
   - 앱 버전

4. **재현 단계**
   - 문제가 발생하기까지의 정확한 단계

5. **추가 정보**
   - 건강 앱에 데이터가 있는지
   - 게이트웨이가 설정되어 있는지
   - 네트워크 연결 상태

## 6. 일반적인 해결책

### 문제: 권한 에러
**해결**: iOS 설정에서 권한 확인 및 재부여

### 문제: 데이터 없음
**해결**: 건강 앱에서 데이터 확인 또는 생성

### 문제: 네트워크 에러
**해결**: 게이트웨이 설정 확인, 연결 테스트

### 문제: 앱이 느려짐
**해결**: 앱 재시작, 디바이스 재부팅

### 문제: 알 수 없는 에러
**해결**: 앱 삭제 후 재설치 (클린 스타트)
