# HTTP 지원 업데이트

## 변경 사항

### HTTPS 강제 제거
이제 HTTP와 HTTPS 모두 사용 가능합니다.

### 이전 (HTTPS만 허용)
```swift
// ❌ HTTPS만 허용
func validate() throws {
    guard baseURL.lowercased().hasPrefix("https://") else {
        throw GatewayError.insecureConnection
    }
}
```

### 현재 (HTTP/HTTPS 모두 허용)
```swift
// ✅ HTTP와 HTTPS 모두 허용
func validate() throws {
    guard URL(string: baseURL) != nil else {
        throw GatewayError.invalidConfiguration
    }
    
    guard baseURL.lowercased().hasPrefix("http://") || 
          baseURL.lowercased().hasPrefix("https://") else {
        throw GatewayError.invalidConfiguration
    }
}
```

## 이유

### 개발 편의성
1. **로컬 개발**: HTTP로 간단하게 테스트 가능
2. **자체 서명 인증서 불필요**: HTTPS 설정 없이 바로 사용
3. **빠른 프로토타이핑**: 인증서 설정 없이 개발 시작

### 유연성
- 개발 환경: HTTP 사용
- 프로덕션 환경: HTTPS 사용
- 선택은 개발자/운영자에게

## 기본 설정

### 개발 환경 (HTTP)
```swift
private let defaultGatewayConfig = GatewayConfig(
    baseURL: "http://192.168.45.185",
    port: 3000,
    apiKey: nil,
    username: nil,
    password: nil
)
```

### URL 예시
```
데이터 전송: http://192.168.45.185:3000/api/v1/health-data/
연결 테스트: http://192.168.45.185:3000/health
```

## 보안 고려사항

### ⚠️ 주의사항
HTTP는 암호화되지 않은 통신입니다:
- 네트워크 상에서 데이터가 평문으로 전송됨
- 중간자 공격(MITM)에 취약
- 민감한 건강 데이터 노출 가능

### 권장 사항

#### 개발 환경
```
✅ HTTP 사용 가능
- 로컬 네트워크에서만 사용
- 외부 네트워크 노출 금지
- 테스트 데이터만 사용
```

#### 프로덕션 환경
```
⚠️ HTTPS 필수
- 유효한 SSL/TLS 인증서 사용
- 공개 네트워크에서 사용
- 실제 사용자 데이터 전송
```

## 사용 방법

### HTTP 사용 (개발)
```swift
let config = GatewayConfig(
    baseURL: "http://192.168.45.185",
    port: 3000,
    apiKey: nil,
    username: nil,
    password: nil
)
```

### HTTPS 사용 (프로덕션)
```swift
let config = GatewayConfig(
    baseURL: "https://api.yourcompany.com",
    port: nil, // 기본 443 포트
    apiKey: "your-api-key",
    username: nil,
    password: nil
)
```

## 게이트웨이 서버 설정

### HTTP 서버 (개발)
```javascript
// Node.js + Express
const express = require('express');
const app = express();

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Gateway is running' });
});

app.post('/api/v1/health-data/', (req, res) => {
  // 데이터 처리
  res.json({
    success: true,
    syncedCount: req.body.samples.length,
    failedCount: 0,
    message: 'All data synced successfully'
  });
});

// HTTP 서버 시작
app.listen(3000, '0.0.0.0', () => {
  console.log('HTTP server running on port 3000');
});
```

### HTTPS 서버 (프로덕션)
```javascript
const https = require('https');
const fs = require('fs');
const express = require('express');

const app = express();
app.use(express.json());

// 엔드포인트 설정
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Gateway is running' });
});

app.post('/api/v1/health-data/', (req, res) => {
  // 데이터 처리
  res.json({
    success: true,
    syncedCount: req.body.samples.length,
    failedCount: 0,
    message: 'All data synced successfully'
  });
});

// HTTPS 서버 시작
const options = {
  key: fs.readFileSync('/path/to/private-key.pem'),
  cert: fs.readFileSync('/path/to/certificate.pem')
};

https.createServer(options, app).listen(443, () => {
  console.log('HTTPS server running on port 443');
});
```

## iOS App Transport Security (ATS)

### HTTP 허용 설정
iOS는 기본적으로 HTTP를 차단합니다. 개발 중 HTTP를 사용하려면 `Info.plist` 설정 필요:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

또는 특정 도메인만 허용:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>192.168.45.185</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

⚠️ **주의**: 프로덕션 빌드에서는 제거해야 합니다!

## 환경별 설정

### 빌드 설정으로 분리
```swift
#if DEBUG
// 개발 환경: HTTP
private let defaultGatewayConfig = GatewayConfig(
    baseURL: "http://192.168.45.185",
    port: 3000,
    apiKey: nil,
    username: nil,
    password: nil
)
#else
// 프로덕션 환경: HTTPS
private let defaultGatewayConfig = GatewayConfig(
    baseURL: "https://api.yourcompany.com",
    port: nil,
    apiKey: nil,
    username: nil,
    password: nil
)
#endif
```

## 테스트

### HTTP 연결 테스트
```bash
# 게이트웨이 서버 실행
cd gateway-server
npm start

# 연결 테스트
curl http://192.168.45.185:3000/health

# 데이터 전송 테스트
curl -X POST http://192.168.45.185:3000/api/v1/health-data/ \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device",
    "userId": "test-user",
    "timestamp": "2024-01-15T10:30:00Z",
    "appVersion": "1.0.0",
    "samples": []
  }'
```

### iOS 앱에서 테스트
1. Info.plist에 ATS 예외 추가
2. 앱 실행
3. 설정 화면에서 "Test Connection" 클릭
4. 메인 화면에서 "Sync Now" 클릭

## 마이그레이션 가이드

### 기존 HTTPS 설정이 있는 경우
- ✅ 그대로 사용 가능
- ✅ 변경 불필요
- ✅ HTTPS가 더 안전함

### HTTP로 변경하려는 경우
1. 설정 화면에서 Base URL 변경
2. `https://` → `http://`
3. Save 버튼 클릭

## 변경된 파일

### 코드
- `health-stack/Models/GatewayConfig.swift` - HTTPS 강제 제거
- `health-stack/Services/GatewayService.swift` - HTTPS 검증 제거
- `health-stack/Managers/ConfigurationManager.swift` - 기본값 HTTP로 변경

### 문서
- `health-stack/API_DATA_SCHEMA.md` - HTTP/HTTPS 모두 가능 명시
- `health-stack/GATEWAY_IMPLEMENTATION_GUIDE.md` - HTTP 예시 추가

## 체크리스트

### 개발 환경
- [x] HTTP 지원 활성화
- [x] 기본 게이트웨이 HTTP로 설정
- [ ] Info.plist에 ATS 예외 추가 (필요시)
- [ ] 게이트웨이 서버 HTTP로 실행

### 프로덕션 환경
- [ ] HTTPS 사용 확인
- [ ] 유효한 SSL 인증서 설치
- [ ] ATS 예외 제거
- [ ] 보안 검토 완료

## 보안 체크리스트

### HTTP 사용 시 (개발)
- [ ] 로컬 네트워크에서만 사용
- [ ] 테스트 데이터만 전송
- [ ] 외부 네트워크 노출 금지
- [ ] 프로덕션 빌드에서 제거

### HTTPS 사용 시 (프로덕션)
- [ ] 유효한 SSL/TLS 인증서
- [ ] 인증서 만료일 관리
- [ ] 강력한 암호화 알고리즘
- [ ] API 키 인증 구현
- [ ] Rate limiting 설정

## 결론

이제 HTTP와 HTTPS 모두 사용 가능합니다:
- ✅ **개발**: HTTP로 빠르게 시작
- ✅ **프로덕션**: HTTPS로 안전하게 운영
- ✅ **유연성**: 환경에 맞게 선택

⚠️ **중요**: 프로덕션 환경에서는 반드시 HTTPS를 사용하세요!
