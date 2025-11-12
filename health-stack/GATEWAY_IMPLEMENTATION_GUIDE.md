# 게이트웨이 구현 가이드

## 개요
iOS 앱에서 전송하는 건강 데이터를 받아 Kafka로 전달하는 게이트웨이 서버 구현 가이드입니다.

## 필수 엔드포인트

### 1. 건강 데이터 수신
```
POST /health/data
Content-Type: application/json
X-API-Key: {apiKey}
```

**요청 본문**: `HealthDataPayload` (자세한 스키마는 `API_DATA_SCHEMA.md` 참조)

**응답**:
```json
{
  "success": true,
  "syncedCount": 100,
  "failedCount": 0,
  "message": "All data synced successfully"
}
```

### 2. 연결 테스트
```
GET /health
```

**응답**:
```json
{
  "status": "ok",
  "message": "Gateway is running"
}
```

## 구현 예시 (Node.js + Express)

### 기본 서버 구조

```javascript
const express = require('express');
const { Kafka } = require('kafkajs');

const app = express();
app.use(express.json({ limit: '10mb' }));

// Kafka 클라이언트 설정
const kafka = new Kafka({
  clientId: 'health-data-gateway',
  brokers: ['localhost:9092']
});

const producer = kafka.producer();

// API 키 검증 미들웨어
const validateApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey || apiKey !== process.env.API_KEY) {
    return res.status(401).json({
      success: false,
      message: 'Invalid API key'
    });
  }
  
  next();
};

// 연결 테스트
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Gateway is running'
  });
});

// 건강 데이터 수신
app.post('/health/data', validateApiKey, async (req, res) => {
  try {
    const { deviceId, userId, samples, timestamp, appVersion } = req.body;
    
    // 유효성 검증
    if (!deviceId || !userId || !samples || !Array.isArray(samples)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid request format'
      });
    }
    
    // Kafka로 전송
    let syncedCount = 0;
    let failedCount = 0;
    
    for (const sample of samples) {
      try {
        await producer.send({
          topic: 'health-data',
          messages: [{
            key: userId,
            value: JSON.stringify({
              deviceId,
              userId,
              sample,
              timestamp,
              appVersion
            })
          }]
        });
        syncedCount++;
      } catch (error) {
        console.error('Failed to send to Kafka:', error);
        failedCount++;
      }
    }
    
    res.json({
      success: failedCount === 0,
      syncedCount,
      failedCount,
      message: failedCount === 0 
        ? 'All data synced successfully' 
        : 'Some data failed to sync'
    });
    
  } catch (error) {
    console.error('Error processing health data:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// 서버 시작
const PORT = process.env.PORT || 3000;

producer.connect().then(() => {
  app.listen(PORT, () => {
    console.log(`Gateway server running on port ${PORT}`);
  });
});
```

## 구현 예시 (Python + FastAPI)

```python
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
from datetime import datetime
from kafka import KafkaProducer
import json
import os

app = FastAPI()

# Kafka 프로듀서 설정
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# 데이터 모델
class HealthDataSample(BaseModel):
    id: str
    type: str
    value: float
    unit: str
    startDate: datetime
    endDate: datetime
    sourceBundle: Optional[str] = None
    metadata: Optional[Dict[str, str]] = None
    isSynced: bool
    createdAt: datetime

class HealthDataPayload(BaseModel):
    deviceId: str
    userId: str
    samples: List[HealthDataSample]
    timestamp: datetime
    appVersion: str

class SyncResponse(BaseModel):
    success: bool
    syncedCount: int
    failedCount: int
    message: str

# API 키 검증
def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != os.getenv('API_KEY'):
        raise HTTPException(status_code=401, detail="Invalid API key")

# 연결 테스트
@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "message": "Gateway is running"
    }

# 건강 데이터 수신
@app.post("/health/data", response_model=SyncResponse)
async def receive_health_data(
    payload: HealthDataPayload,
    x_api_key: str = Header(...)
):
    verify_api_key(x_api_key)
    
    synced_count = 0
    failed_count = 0
    
    for sample in payload.samples:
        try:
            # Kafka로 전송
            producer.send(
                'health-data',
                key=payload.userId.encode('utf-8'),
                value={
                    'deviceId': payload.deviceId,
                    'userId': payload.userId,
                    'sample': sample.dict(),
                    'timestamp': payload.timestamp.isoformat(),
                    'appVersion': payload.appVersion
                }
            )
            synced_count += 1
        except Exception as e:
            print(f"Failed to send to Kafka: {e}")
            failed_count += 1
    
    producer.flush()
    
    return SyncResponse(
        success=failed_count == 0,
        syncedCount=synced_count,
        failedCount=failed_count,
        message="All data synced successfully" if failed_count == 0 else "Some data failed to sync"
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3000)
```

## Kafka 토픽 구조

### 토픽 이름
```
health-data
```

### 메시지 키
```
userId (string)
```
- 같은 사용자의 데이터를 같은 파티션으로 라우팅
- 순서 보장

### 메시지 값 (JSON)
```json
{
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "user123",
  "sample": {
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
  "timestamp": "2024-01-15T10:30:00Z",
  "appVersion": "1.0.0"
}
```

## 보안 고려사항

### 1. HTTPS 필수
```nginx
server {
    listen 443 ssl;
    server_name gateway.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;
    }
}
```

### 2. API 키 관리
```bash
# 환경 변수로 관리
export API_KEY="your-secure-api-key-here"
```

### 3. Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100 // 최대 100 요청
});

app.use('/health/data', limiter);
```

### 4. 요청 크기 제한
```javascript
app.use(express.json({ limit: '10mb' }));
```

## 모니터링

### 로깅
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

app.post('/health/data', async (req, res) => {
  logger.info('Received health data', {
    userId: req.body.userId,
    sampleCount: req.body.samples.length
  });
  // ...
});
```

### 메트릭
```javascript
const prometheus = require('prom-client');

const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

const samplesReceived = new prometheus.Counter({
  name: 'health_samples_received_total',
  help: 'Total number of health samples received',
  labelNames: ['userId', 'dataType']
});
```

## 에러 처리

### 재시도 가능한 에러
- 네트워크 오류
- Kafka 일시적 장애
- 서버 과부하 (503)

### 재시도 불가능한 에러
- 인증 실패 (401)
- 잘못된 요청 (400)
- 권한 없음 (403)

## 테스트

### cURL 테스트
```bash
# 연결 테스트
curl https://gateway.example.com/health

# 데이터 전송 테스트
curl -X POST https://gateway.example.com/health/data \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d @sample-data.json
```

### sample-data.json
```json
{
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
}
```

## 배포

### Docker
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

### docker-compose.yml
```yaml
version: '3.8'

services:
  gateway:
    build: .
    ports:
      - "3000:3000"
    environment:
      - API_KEY=${API_KEY}
      - KAFKA_BROKERS=kafka:9092
    depends_on:
      - kafka
  
  kafka:
    image: confluentinc/cp-kafka:latest
    ports:
      - "9092:9092"
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
  
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
```

## 성능 최적화

### 배치 처리
- 클라이언트는 최대 100개씩 배치로 전송
- 서버는 배치를 받아 Kafka로 전송

### 비동기 처리
- Kafka 전송을 비동기로 처리
- 빠른 응답 반환

### 연결 풀링
- Kafka 프로듀서 재사용
- 데이터베이스 연결 풀 사용

## 참고 자료
- [API 데이터 스키마](./API_DATA_SCHEMA.md)
- [Kafka 공식 문서](https://kafka.apache.org/documentation/)
- [Express.js](https://expressjs.com/)
- [FastAPI](https://fastapi.tiangolo.com/)
