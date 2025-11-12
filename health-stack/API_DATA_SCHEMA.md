# Health Data API 스키마

## 개요
iOS 앱에서 게이트웨이로 전송하는 건강 데이터의 JSON 스키마입니다.

## HTTP 요청

### Endpoint
```
POST /health/data
```

### Headers
```
Content-Type: application/json
X-API-Key: {apiKey}                    # API 키 인증 (선택)
Authorization: Basic {base64Credentials} # Basic 인증 (선택)
```

## 요청 본문 (Request Body)

### HealthDataPayload

```json
{
  "deviceId": "string (UUID)",
  "userId": "string",
  "samples": [HealthDataSample],
  "timestamp": "string (ISO 8601)",
  "appVersion": "string"
}
```

#### 필드 설명

| 필드 | 타입 | 필수 | 설명 | 예시 |
|------|------|------|------|------|
| `deviceId` | string | ✅ | 디바이스 고유 식별자 (UUID) | `"550e8400-e29b-41d4-a716-446655440000"` |
| `userId` | string | ✅ | 사용자 식별자 | `"user123"` |
| `samples` | array | ✅ | 건강 데이터 샘플 배열 (최대 100개) | 아래 참조 |
| `timestamp` | string | ✅ | 전송 시각 (ISO 8601) | `"2024-01-15T10:30:00Z"` |
| `appVersion` | string | ✅ | 앱 버전 | `"1.0.0"` |

### HealthDataSample

```json
{
  "id": "string (UUID)",
  "type": "string",
  "value": number,
  "unit": "string",
  "startDate": "string (ISO 8601)",
  "endDate": "string (ISO 8601)",
  "sourceBundle": "string (optional)",
  "metadata": {
    "key": "value"
  },
  "isSynced": boolean,
  "createdAt": "string (ISO 8601)"
}
```

#### 필드 설명

| 필드 | 타입 | 필수 | 설명 | 예시 |
|------|------|------|------|------|
| `id` | string | ✅ | 샘플 고유 식별자 (UUID) | `"123e4567-e89b-12d3-a456-426614174000"` |
| `type` | string | ✅ | 건강 데이터 타입 | `"stepCount"`, `"heartRate"` |
| `value` | number | ✅ | 측정값 | `10000`, `72.5` |
| `unit` | string | ✅ | 측정 단위 | `"count"`, `"count/min"`, `"kg"` |
| `startDate` | string | ✅ | 측정 시작 시각 (ISO 8601) | `"2024-01-15T09:00:00Z"` |
| `endDate` | string | ✅ | 측정 종료 시각 (ISO 8601) | `"2024-01-15T10:00:00Z"` |
| `sourceBundle` | string | ❌ | 데이터 소스 앱 번들 ID | `"com.apple.health"` |
| `metadata` | object | ❌ | 추가 메타데이터 (키-값 쌍) | `{"device": "Apple Watch"}` |
| `isSynced` | boolean | ✅ | 동기화 상태 | `false` |
| `createdAt` | string | ✅ | 로컬 생성 시각 (ISO 8601) | `"2024-01-15T10:30:00Z"` |

## 요청 예시

### 단일 배치 (걸음 수 데이터)

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
      "value": 1500,
      "unit": "count",
      "startDate": "2024-01-15T09:00:00Z",
      "endDate": "2024-01-15T10:00:00Z",
      "sourceBundle": "com.apple.health",
      "metadata": {
        "device": "iPhone"
      },
      "isSynced": false,
      "createdAt": "2024-01-15T10:30:00Z"
    },
    {
      "id": "234e5678-e89b-12d3-a456-426614174001",
      "type": "stepCount",
      "value": 2300,
      "unit": "count",
      "startDate": "2024-01-15T10:00:00Z",
      "endDate": "2024-01-15T11:00:00Z",
      "sourceBundle": "com.apple.health",
      "metadata": null,
      "isSynced": false,
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### 다양한 데이터 타입

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
      "sourceBundle": "com.apple.health",
      "metadata": null,
      "isSynced": false,
      "createdAt": "2024-01-15T10:30:00Z"
    },
    {
      "id": "234e5678-e89b-12d3-a456-426614174001",
      "type": "heartRate",
      "value": 72,
      "unit": "count/min",
      "startDate": "2024-01-15T10:00:00Z",
      "endDate": "2024-01-15T10:00:00Z",
      "sourceBundle": "com.apple.health",
      "metadata": {
        "context": "resting"
      },
      "isSynced": false,
      "createdAt": "2024-01-15T10:30:00Z"
    },
    {
      "id": "345e6789-e89b-12d3-a456-426614174002",
      "type": "bodyMass",
      "value": 70.5,
      "unit": "kg",
      "startDate": "2024-01-15T08:00:00Z",
      "endDate": "2024-01-15T08:00:00Z",
      "sourceBundle": "com.apple.health",
      "metadata": null,
      "isSynced": false,
      "createdAt": "2024-01-15T10:30:00Z"
    },
    {
      "id": "456e7890-e89b-12d3-a456-426614174003",
      "type": "sleepAnalysis",
      "value": 480,
      "unit": "min",
      "startDate": "2024-01-14T23:00:00Z",
      "endDate": "2024-01-15T07:00:00Z",
      "sourceBundle": "com.apple.health",
      "metadata": {
        "sleepCategory": "asleepCore"
      },
      "isSynced": false,
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

## 응답 (Response)

### SyncResponse

```json
{
  "success": boolean,
  "syncedCount": number,
  "failedCount": number,
  "message": "string"
}
```

#### 필드 설명

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `success` | boolean | 전체 동기화 성공 여부 | `true` |
| `syncedCount` | number | 성공적으로 동기화된 샘플 수 | `100` |
| `failedCount` | number | 실패한 샘플 수 | `0` |
| `message` | string | 응답 메시지 | `"All data synced successfully"` |

### 성공 응답 예시

```json
{
  "success": true,
  "syncedCount": 100,
  "failedCount": 0,
  "message": "All data synced successfully"
}
```

### 부분 성공 응답 예시

```json
{
  "success": false,
  "syncedCount": 95,
  "failedCount": 5,
  "message": "Some data failed to sync"
}
```

## 데이터 타입 (type) 목록

### 신체 측정 (Body Measurements)
- `height` - 키 (cm)
- `bodyMass` - 체중 (kg)
- `bodyMassIndex` - BMI (count)
- `bodyFatPercentage` - 체지방률 (%)
- `leanBodyMass` - 제지방량 (kg)
- `waistCircumference` - 허리둘레 (cm)

### 활동 (Activity)
- `stepCount` - 걸음 수 (count)
- `distanceWalkingRunning` - 걷기/달리기 거리 (m)
- `flightsClimbed` - 오른 층수 (count)
- `activeEnergyBurned` - 활동 칼로리 (kcal)
- `basalEnergyBurned` - 기초 칼로리 (kcal)
- `exerciseTime` - 운동 시간 (s)
- `standHours` - 서 있는 시간 (s)

### 심혈관 (Cardiovascular)
- `heartRate` - 심박수 (count/min)
- `restingHeartRate` - 안정 시 심박수 (count/min)
- `heartRateVariability` - 심박 변이도 (ms)
- `bloodPressureSystolic` - 수축기 혈압 (mmHg)
- `bloodPressureDiastolic` - 이완기 혈압 (mmHg)
- `oxygenSaturation` - 산소포화도 (%)

### 수면 (Sleep)
- `sleepAnalysis` - 수면 분석 (min)
- `timeInBed` - 침대에 있던 시간 (min)

### 영양 (Nutrition)
- `dietaryEnergy` - 섭취 칼로리 (kcal)
- `dietaryProtein` - 단백질 (g)
- `dietaryCarbohydrates` - 탄수화물 (g)
- `dietaryFat` - 지방 (g)
- `dietaryFiber` - 식이섬유 (g)
- `dietarySugar` - 당류 (g)
- `dietaryWater` - 수분 (mL)

### 호흡 (Respiratory)
- `respiratoryRate` - 호흡수 (count/min)
- `vo2Max` - 최대 산소 섭취량 (mL/kg/min)

### 기타 (Other)
- `bloodGlucose` - 혈당 (mg/dL)
- `bodyTemperature` - 체온 (°C)
- `mindfulMinutes` - 마음챙김 시간 (min)

## 배치 처리

### 배치 크기
- 최대 배치 크기: **100개 샘플**
- 100개 초과 시 자동으로 여러 배치로 분할

### 배치 전송 예시
```
총 250개 샘플 → 3개 배치로 분할
- Batch 1: 100 samples
- Batch 2: 100 samples
- Batch 3: 50 samples
```

## 인증 (Authentication)

### API 키 인증
```
X-API-Key: your-api-key-here
```

### Basic 인증
```
Authorization: Basic base64(username:password)
```

### 둘 다 사용 가능
```
X-API-Key: your-api-key-here
Authorization: Basic base64(username:password)
```

## 보안

### HTTPS 필수
- 모든 요청은 **HTTPS**를 통해서만 전송
- HTTP 요청은 자동으로 거부됨

### 데이터 보호
- 디바이스에서 암호화 저장 (FileProtection.complete)
- 전송 중 TLS 암호화
- 민감한 건강 데이터 보호

## 에러 처리

### 클라이언트 에러 (4xx)
- `400 Bad Request` - 잘못된 요청 형식
- `401 Unauthorized` - 인증 실패
- `403 Forbidden` - 권한 없음

### 서버 에러 (5xx)
- `500 Internal Server Error` - 서버 내부 오류
- `503 Service Unavailable` - 서비스 이용 불가

### 재시도 정책
- 최대 재시도 횟수: **5회**
- 재시도 간격: **지수 백오프** (1s, 2s, 4s, 8s, 16s)
- 인증 오류는 재시도하지 않음

## 테스트 엔드포인트

### 연결 테스트
```
GET /health
```

#### 응답
```json
{
  "status": "ok",
  "message": "Gateway is running"
}
```

## 구현 참고사항

### 타임스탬프 형식
- ISO 8601 형식 사용
- UTC 시간대 권장
- 예: `2024-01-15T10:30:00Z`

### UUID 형식
- RFC 4122 표준
- 소문자 사용
- 예: `550e8400-e29b-41d4-a716-446655440000`

### 단위 일관성
- HealthKit 표준 단위 사용
- 단위 변환은 클라이언트에서 수행
- 서버는 받은 단위 그대로 저장

## 관련 파일
- `health-stack/Models/HealthDataPayload.swift` - 페이로드 모델
- `health-stack/Models/HealthDataSample.swift` - 샘플 모델
- `health-stack/Services/GatewayService.swift` - 전송 로직
- `health-stack/Models/SyncResponse.swift` - 응답 모델
