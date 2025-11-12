# 데이터 스키마 요약

## 빠른 참조

### 전송 데이터 구조
```
HealthDataPayload
├── deviceId (UUID)
├── userId (string)
├── timestamp (ISO 8601)
├── appVersion (string)
└── samples[] (최대 100개)
    └── HealthDataSample
        ├── id (UUID)
        ├── type (string)
        ├── value (number)
        ├── unit (string)
        ├── startDate (ISO 8601)
        ├── endDate (ISO 8601)
        ├── sourceBundle (string, optional)
        ├── metadata (object, optional)
        ├── isSynced (boolean)
        └── createdAt (ISO 8601)
```

### API 엔드포인트
```
POST /api/v1/health-data/ (데이터 전송)
GET  /health              (연결 테스트)
```

### 인증
```
X-API-Key: {apiKey}
Authorization: Basic {base64Credentials}
```

## 주요 데이터 타입

### 활동 데이터
| 타입 | 단위 | 설명 |
|------|------|------|
| stepCount | count | 걸음 수 |
| distanceWalkingRunning | m | 걷기/달리기 거리 |
| activeEnergyBurned | kcal | 활동 칼로리 |
| exerciseTime | s | 운동 시간 (초) |

### 심혈관 데이터
| 타입 | 단위 | 설명 |
|------|------|------|
| heartRate | count/min | 심박수 |
| bloodPressureSystolic | mmHg | 수축기 혈압 |
| bloodPressureDiastolic | mmHg | 이완기 혈압 |
| oxygenSaturation | % | 산소포화도 |

### 신체 측정
| 타입 | 단위 | 설명 |
|------|------|------|
| height | cm | 키 |
| bodyMass | kg | 체중 |
| bodyMassIndex | count | BMI |
| bodyFatPercentage | % | 체지방률 |

### 수면 데이터
| 타입 | 단위 | 설명 |
|------|------|------|
| sleepAnalysis | min | 수면 시간 |
| timeInBed | min | 침대에 있던 시간 |

## 예시 JSON

### 최소 요청
```json
{
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "user123",
  "timestamp": "2024-01-15T10:30:00Z",
  "appVersion": "1.0.0",
  "samples": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "type": "stepCount",
      "value": 10000,
      "unit": "count",
      "startDate": "2024-01-15T00:00:00Z",
      "endDate": "2024-01-15T23:59:59Z",
      "sourceBundle": null,
      "metadata": null,
      "isSynced": false,
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### 응답
```json
{
  "success": true,
  "syncedCount": 1,
  "failedCount": 0,
  "message": "All data synced successfully"
}
```

## 구현 체크리스트

### 게이트웨이 서버
- [ ] POST /health/data 엔드포인트 구현
- [ ] GET /health 엔드포인트 구현
- [ ] API 키 인증 구현
- [ ] HTTPS 설정
- [ ] Kafka 프로듀서 연결
- [ ] 에러 처리 및 로깅
- [ ] Rate limiting

### Kafka 설정
- [ ] 토픽 생성: `health-data`
- [ ] 파티션 설정 (권장: 3개 이상)
- [ ] 리플리케이션 설정 (권장: 2개 이상)
- [ ] 보존 기간 설정

### 모니터링
- [ ] 로그 수집
- [ ] 메트릭 수집 (Prometheus)
- [ ] 알림 설정
- [ ] 대시보드 구성 (Grafana)

## 보안 체크리스트
- [ ] HTTPS 강제 (HTTP 차단)
- [ ] API 키 환경 변수 관리
- [ ] Rate limiting 설정
- [ ] 요청 크기 제한 (10MB)
- [ ] CORS 설정 (필요시)
- [ ] 입력 유효성 검증

## 테스트 시나리오

### 1. 연결 테스트
```bash
curl https://gateway.example.com/health
# 예상: {"status":"ok","message":"Gateway is running"}
```

### 2. 인증 테스트
```bash
# 잘못된 API 키
curl -X POST https://gateway.example.com/health/data \
  -H "X-API-Key: wrong-key" \
  -d '{}'
# 예상: 401 Unauthorized

# 올바른 API 키
curl -X POST https://gateway.example.com/health/data \
  -H "X-API-Key: correct-key" \
  -d @sample-data.json
# 예상: 200 OK
```

### 3. 데이터 전송 테스트
```bash
# iOS 앱에서 수동 싱크 실행
# 게이트웨이 로그 확인
# Kafka 토픽에서 메시지 확인
```

## 문제 해결

### 앱에서 "Gateway not configured" 경고
- 설정 화면에서 게이트웨이 URL 입력
- HTTPS URL 사용 (HTTP는 거부됨)
- API 키 입력 (선택사항)
- "Test Connection" 버튼으로 확인

### 연결 테스트 실패
- URL이 올바른지 확인
- HTTPS 인증서가 유효한지 확인
- 방화벽/네트워크 설정 확인
- 서버가 실행 중인지 확인

### 데이터 전송 실패
- API 키가 올바른지 확인
- 요청 형식이 올바른지 확인
- 서버 로그에서 에러 확인
- Kafka 연결 상태 확인

## 성능 지표

### 예상 처리량
- 단일 요청: 100 samples
- 초당 요청: ~10 requests/sec
- 초당 샘플: ~1,000 samples/sec

### 응답 시간
- 연결 테스트: < 100ms
- 데이터 전송: < 500ms (100 samples)

### 리소스 사용
- CPU: < 50% (일반적인 부하)
- 메모리: < 512MB
- 네트워크: < 10MB/min

## 관련 문서
- [상세 API 스키마](./API_DATA_SCHEMA.md)
- [게이트웨이 구현 가이드](./GATEWAY_IMPLEMENTATION_GUIDE.md)
- [프로젝트 설정 가이드](./PROJECT_SETUP_GUIDE.md)

## 다음 단계

1. **게이트웨이 서버 구현**
   - Node.js 또는 Python 선택
   - 기본 엔드포인트 구현
   - Kafka 연결

2. **테스트**
   - 로컬에서 게이트웨이 실행
   - iOS 앱에서 연결 테스트
   - 데이터 전송 테스트

3. **배포**
   - Docker 이미지 빌드
   - 클라우드 배포 (AWS, GCP, Azure)
   - HTTPS 인증서 설정

4. **모니터링**
   - 로그 수집 설정
   - 메트릭 대시보드 구성
   - 알림 설정

5. **최적화**
   - 성능 튜닝
   - 스케일링 설정
   - 캐싱 구현
