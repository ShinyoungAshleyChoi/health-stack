# 기본 게이트웨이 설정

## 개요
앱에 기본 게이트웨이 주소가 설정되어 있어, 별도 설정 없이도 바로 사용할 수 있습니다.

## 기본 설정

### 게이트웨이 주소
```
https://192.168.45.185:3000
```

### 설정 내용
- **Base URL**: `https://192.168.45.185`
- **Port**: `3000`
- **API Key**: 없음 (선택사항)
- **Username**: 없음 (선택사항)
- **Password**: 없음 (선택사항)

## 동작 방식

### 1. 첫 실행 시
- 사용자가 게이트웨이를 설정하지 않아도 기본 주소 사용
- 설정 화면에서 "Test Connection" 가능
- 수동 싱크 즉시 사용 가능

### 2. 사용자 정의 설정
- 설정 화면에서 다른 주소로 변경 가능
- 변경 시 기본 설정 대신 사용자 설정 사용
- 언제든지 초기화 가능

### 3. 설정 우선순위
```
사용자 설정 > 기본 설정
```

## 코드 구현

### ConfigurationManager.swift
```swift
// Default gateway configuration
private let defaultGatewayConfig = GatewayConfig(
    baseURL: "https://192.168.45.185",
    port: 3000,
    apiKey: nil,
    username: nil,
    password: nil
)

func getGatewayConfig() throws -> GatewayConfig? {
    // Check if user has saved a custom configuration
    if let baseURL = userDefaults.string(forKey: UserDefaultsKeys.gatewayBaseURL) {
        // Return user configuration
        // ...
    } else {
        // Return default configuration
        return defaultGatewayConfig
    }
}
```

## 사용 방법

### 기본 설정으로 사용
1. 앱 실행
2. 온보딩 완료
3. 메인 화면에서 "Sync Now" 클릭
4. 자동으로 `https://192.168.45.185:3000`으로 전송

### 다른 주소로 변경
1. 설정 화면 이동
2. "Gateway Configuration" 섹션
3. Base URL 입력: `https://your-gateway.com`
4. Port 입력: `8080` (선택)
5. API Key 입력 (선택)
6. "Save" 버튼 클릭

### 기본 설정으로 초기화
1. 설정 화면에서 모든 필드 삭제
2. "Save" 버튼 클릭
3. 다시 기본 설정 사용

## 네트워크 요구사항

### 로컬 네트워크
기본 주소 `192.168.45.185`는 로컬 네트워크 주소입니다:
- 같은 Wi-Fi 네트워크에 연결 필요
- 게이트웨이 서버가 해당 IP에서 실행 중이어야 함
- 포트 3000이 열려 있어야 함

### HTTPS 인증서
로컬 IP에서 HTTPS를 사용하려면:
1. 자체 서명 인증서 생성
2. iOS에서 인증서 신뢰 설정 필요

#### 자체 서명 인증서 생성
```bash
# OpenSSL로 인증서 생성
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Node.js 서버에서 사용
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
};

https.createServer(options, app).listen(3000);
```

#### iOS에서 인증서 신뢰
1. 인증서를 이메일로 전송하거나 AirDrop
2. 설정 > 일반 > VPN 및 기기 관리
3. 다운로드한 프로파일 설치
4. 설정 > 일반 > 정보 > 인증서 신뢰 설정
5. 해당 인증서 활성화

### 개발 중 임시 해결책
개발 중에는 App Transport Security (ATS) 예외 설정:

**Info.plist**
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

⚠️ **주의**: 프로덕션에서는 절대 사용하지 마세요!

## 테스트

### 1. 연결 테스트
```bash
# 게이트웨이 서버 실행 확인
curl https://192.168.45.185:3000/health

# 예상 응답
{
  "status": "ok",
  "message": "Gateway is running"
}
```

### 2. 앱에서 테스트
1. 설정 화면 이동
2. "Test Connection" 버튼 클릭
3. 성공 메시지 확인

### 3. 데이터 전송 테스트
1. 메인 화면에서 "Sync Now" 클릭
2. 진행률 0% → 100% 확인
3. 게이트웨이 로그에서 데이터 수신 확인

## 문제 해결

### "Connection failed" 에러
**원인**: 게이트웨이 서버가 실행되지 않음

**해결**:
```bash
# 게이트웨이 서버 실행
cd gateway-server
npm start
```

### "SSL certificate error" 에러
**원인**: 자체 서명 인증서를 신뢰하지 않음

**해결**:
1. iOS 설정에서 인증서 신뢰 설정
2. 또는 개발 중에는 ATS 예외 설정

### "Network unreachable" 에러
**원인**: 다른 네트워크에 연결됨

**해결**:
1. 같은 Wi-Fi 네트워크 연결 확인
2. IP 주소 확인:
```bash
# Mac에서 IP 확인
ifconfig | grep "inet "

# 게이트웨이 서버의 IP와 일치하는지 확인
```

### "Gateway not configured" 경고
**원인**: 기본 설정이 로드되지 않음 (드물게 발생)

**해결**:
1. 앱 재시작
2. 설정 화면에서 수동으로 주소 입력
3. 앱 재설치 (마지막 수단)

## 프로덕션 배포 시

### 실제 도메인 사용
```swift
private let defaultGatewayConfig = GatewayConfig(
    baseURL: "https://api.yourcompany.com",
    port: nil, // 기본 443 포트 사용
    apiKey: nil,
    username: nil,
    password: nil
)
```

### 환경별 설정
```swift
#if DEBUG
private let defaultGatewayConfig = GatewayConfig(
    baseURL: "https://192.168.45.185",
    port: 3000,
    apiKey: nil,
    username: nil,
    password: nil
)
#else
private let defaultGatewayConfig = GatewayConfig(
    baseURL: "https://api.yourcompany.com",
    port: nil,
    apiKey: nil,
    username: nil,
    password: nil
)
#endif
```

## 보안 고려사항

### 로컬 개발
- ✅ 로컬 네트워크에서만 접근 가능
- ✅ 외부에서 접근 불가
- ⚠️ 자체 서명 인증서 사용 시 주의

### 프로덕션
- ✅ 유효한 SSL 인증서 사용
- ✅ API 키 인증 구현
- ✅ Rate limiting 설정
- ✅ 방화벽 설정

## 관련 파일
- `health-stack/Managers/ConfigurationManager.swift` - 기본 설정 정의
- `health-stack/Models/GatewayConfig.swift` - 설정 모델
- `health-stack/Services/GatewayService.swift` - 게이트웨이 통신

## 다음 단계

1. **게이트웨이 서버 실행**
   ```bash
   cd gateway-server
   npm install
   npm start
   ```

2. **앱 실행 및 테스트**
   - Xcode에서 빌드
   - 실기기에서 실행
   - 수동 싱크 테스트

3. **데이터 확인**
   - 게이트웨이 로그 확인
   - Kafka 토픽에서 메시지 확인

이제 별도 설정 없이 바로 사용할 수 있습니다! 🎉
