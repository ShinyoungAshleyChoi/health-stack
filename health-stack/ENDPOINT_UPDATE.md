# API 엔드포인트 업데이트

## 변경 사항

### 데이터 전송 엔드포인트
```diff
- POST /health/data
+ POST /api/v1/health-data/
```

### 연결 테스트 엔드포인트 (변경 없음)
```
GET /health
```

## 이유

### RESTful API 베스트 프랙티스
1. **버전 관리**: `/api/v1/` - API 버전을 명시하여 향후 변경 용이
2. **명확한 리소스 이름**: `health-data` - 복수형 사용
3. **일관성**: 표준 REST API 패턴 준수

### 장점
- ✅ API 버전 관리 가능 (v1, v2, ...)
- ✅ 다른 엔드포인트와 구분 명확
- ✅ 확장성 향상
- ✅ 표준 규칙 준수

## 코드 변경

### GatewayService.swift
```swift
// ✅ 변경됨
private func sendBatch(batch: [HealthDataSample], config: GatewayConfig) async throws -> SyncResponse {
    let url = buildURL(config: config, path: "/api/v1/health-data/")
    let headers = buildHeaders(config: config)
    // ...
}

// ✅ 변경 없음 (헬스체크용)
func testConnection() async throws -> Bool {
    let url = buildURL(config: config, path: "/health")
    // ...
}
```

## 전체 URL 예시

### 개발 환경
```
데이터 전송: https://192.168.45.185:3000/api/v1/health-data/
연결 테스트: https://192.168.45.185:3000/health
```

### 프로덕션 환경
```
데이터 전송: https://api.yourcompany.com/api/v1/health-data/
연결 테스트: https://api.yourcompany.com/health
```

## 게이트웨이 서버 구현

### Node.js + Express
```javascript
const express = require('express');
const app = express();

// 연결 테스트 (변경 없음)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Gateway is running'
  });
});

// 데이터 수신 (새 엔드포인트)
app.post('/api/v1/health-data/', validateApiKey, async (req, res) => {
  try {
    const { deviceId, userId, samples, timestamp, appVersion } = req.body;
    
    // 데이터 처리
    // ...
    
    res.json({
      success: true,
      syncedCount: samples.length,
      failedCount: 0,
      message: 'All data synced successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

app.listen(3000);
```

### Python + FastAPI
```python
from fastapi import FastAPI

app = FastAPI()

# 연결 테스트 (변경 없음)
@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "message": "Gateway is running"
    }

# 데이터 수신 (새 엔드포인트)
@app.post("/api/v1/health-data/", response_model=SyncResponse)
async def receive_health_data(
    payload: HealthDataPayload,
    x_api_key: str = Header(...)
):
    verify_api_key(x_api_key)
    
    # 데이터 처리
    # ...
    
    return SyncResponse(
        success=True,
        syncedCount=len(payload.samples),
        failedCount=0,
        message="All data synced successfully"
    )
```

## 테스트

### cURL 테스트
```bash
# 연결 테스트 (변경 없음)
curl https://192.168.45.185:3000/health

# 데이터 전송 (새 엔드포인트)
curl -X POST https://192.168.45.185:3000/api/v1/health-data/ \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "deviceId": "550e8400-e29b-41d4-a716-446655440000",
    "userId": "test-user",
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
        "sourceBundle": "com.apple.health",
        "metadata": null,
        "isSynced": false,
        "createdAt": "2024-01-15T10:30:00Z"
      }
    ]
  }'
```

### iOS 앱에서 테스트
1. 앱 실행
2. 메인 화면에서 "Sync Now" 클릭
3. Xcode 콘솔에서 로그 확인:
```
[NetworkClient] Sending POST request to https://192.168.45.185:3000/api/v1/health-data/
[NetworkClient] Response status: 200
[SyncManager] Successfully sent batch 1/1 with 100 samples
```

## 마이그레이션 가이드

### 기존 게이트웨이 서버가 있는 경우

#### 옵션 1: 새 엔드포인트 추가 (권장)
```javascript
// 기존 엔드포인트 유지 (하위 호환성)
app.post('/health/data', handleHealthData);

// 새 엔드포인트 추가
app.post('/api/v1/health-data/', handleHealthData);
```

#### 옵션 2: 리다이렉트
```javascript
// 기존 엔드포인트에서 새 엔드포인트로 리다이렉트
app.post('/health/data', (req, res) => {
  res.redirect(307, '/api/v1/health-data/');
});

// 새 엔드포인트
app.post('/api/v1/health-data/', handleHealthData);
```

#### 옵션 3: 완전 교체
```javascript
// 기존 엔드포인트 제거
// app.post('/health/data', handleHealthData);

// 새 엔드포인트만 사용
app.post('/api/v1/health-data/', handleHealthData);
```

## 향후 확장 가능성

### API 버전 관리
```
/api/v1/health-data/  - 현재 버전
/api/v2/health-data/  - 향후 버전 (새 기능 추가 시)
```

### 추가 엔드포인트
```
POST /api/v1/health-data/        - 데이터 전송
GET  /api/v1/health-data/        - 데이터 조회
GET  /api/v1/health-data/:id     - 특정 데이터 조회
DELETE /api/v1/health-data/:id   - 데이터 삭제
GET  /api/v1/health-data/stats   - 통계 조회
```

### 다른 리소스
```
POST /api/v1/users/              - 사용자 등록
GET  /api/v1/users/:id           - 사용자 조회
POST /api/v1/devices/            - 디바이스 등록
GET  /api/v1/sync-history/       - 동기화 이력
```

## 호환성

### iOS 앱
- ✅ 자동으로 새 엔드포인트 사용
- ✅ 코드 변경 없이 작동
- ✅ 기존 저장된 데이터도 새 엔드포인트로 전송

### 게이트웨이 서버
- ⚠️ 새 엔드포인트 구현 필요
- ✅ 기존 엔드포인트 유지 가능 (하위 호환성)
- ✅ 점진적 마이그레이션 가능

## 체크리스트

### iOS 앱 (완료)
- [x] GatewayService.swift 업데이트
- [x] API_DATA_SCHEMA.md 업데이트
- [x] DATA_SCHEMA_SUMMARY.md 업데이트
- [x] GATEWAY_IMPLEMENTATION_GUIDE.md 업데이트

### 게이트웨이 서버 (TODO)
- [ ] 새 엔드포인트 구현
- [ ] 기존 엔드포인트 처리 결정 (유지/리다이렉트/제거)
- [ ] 테스트
- [ ] 배포

## 관련 문서
- [API 데이터 스키마](./API_DATA_SCHEMA.md)
- [게이트웨이 구현 가이드](./GATEWAY_IMPLEMENTATION_GUIDE.md)
- [데이터 스키마 요약](./DATA_SCHEMA_SUMMARY.md)

## 결론

엔드포인트가 `/api/v1/health-data/`로 변경되어:
- ✅ RESTful API 표준 준수
- ✅ 버전 관리 가능
- ✅ 확장성 향상
- ✅ 명확한 리소스 구조

게이트웨이 서버에서 새 엔드포인트를 구현하면 바로 사용할 수 있습니다! 🚀
