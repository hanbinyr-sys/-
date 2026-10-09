# 붕어빵 타이쿤 — 로그인과 홈화면

## 현재 완성된 부분

- 도트 스타일 로그인 화면 → 홈화면 → 게임
- 이메일 인증번호로 가입/로그인, 로그인 상태 유지, 로그아웃
- 홈의 새 게임 / 불러오기, 가게 이름·일차·돈·판매량·마지막 저장 표시
- 계정별 서버 저장, 5초 간격 자동 저장, 홈으로 돌아갈 때 즉시 저장
- 게스트 플레이와 기존 브라우저 기록 / JSON 저장 파일 가져오기
- 홈·로그인 화면 및 브라우저가 백그라운드인 동안 게임 시간 정지
- 저장 실패 시 계정별 로컬 임시 보관과 재시도, 다른 기기의 변경과 충돌하면 덮어쓰기 중단
- 기존 불판, 붕어빵 디자인, 인기 칭호, 상점, 콤보·피버 유지

현재 config.js의 연결 값은 비어 있습니다. 실제 로그인은 아래 Supabase 프로젝트 설정을 마쳐야 활성화됩니다. 설정 전에는 게스트로 화면과 게임을 테스트할 수 있습니다. 이메일을 입력한 것만으로 로그인 처리하지 않습니다.

## 1. Supabase 프로젝트 만들기

https://supabase.com/dashboard 에서 계정을 만들고 프로젝트를 생성합니다.
프로젝트의 Connect 또는 Settings의 API 관련 화면에서 다음 공개 연결 정보를 찾습니다.

- Project URL: https://프로젝트ID.supabase.co
- Publishable key: sb_publishable_... (또는 기존 anon public 키)

config.js의 빈 문자열 두 곳에 넣습니다. secret 키, service_role 키, 데이터베이스 비밀번호를 브라우저 파일이나 GitHub 저장소에 넣지 않습니다.

```js
window.BUNGEO_CONFIG = {
  supabaseUrl: "https://프로젝트ID.supabase.co",
  supabasePublishableKey: "sb_publishable_공개키"
};
```

## 2. 저장 테이블과 계정 삭제 함수

Supabase의 SQL Editor에서 아래 두 파일을 순서대로 하나씩 붙여 넣고 Run을 누릅니다.

1. supabase_저장테이블.sql: 계정별 저장 테이블 bungeo_saves, RLS 권한, 저장 버전을 확인하는 함수 save_bungeo를 만듭니다. 기존 게임 기록을 삭제하지 않으며 여러 번 실행해도 됩니다. 다른 사용자 데이터는 읽거나 수정할 수 없도록 auth.uid()로 제한합니다.
2. supabase_계정삭제.sql: 앱 안에서 본인 계정과 가게 기록을 지우는 함수 delete_bungeo_account를 만듭니다. 로그인한 본인 계정만 지울 수 있습니다.

저장 데이터는 계정당 한 개입니다. 새 게임은 기존 저장을 교체하므로 확인 창을 거칩니다.

## 3. 이메일 인증번호 설정

Authentication에서 Email 로그인을 활성화하고 신규 가입을 허용합니다.
이메일 템플릿의 Magic Link와 Confirm signup에 인증번호가 표시되도록 아래 내용을 사용합니다.

```html
<h2>붕어빵 타이쿤 로그인</h2>
<p>게임 화면에 아래 인증번호를 입력해 주세요.</p>
<p style="font-size:28px;letter-spacing:4px">{{ .Token }}</p>
<p>요청하지 않았다면 이 메일을 무시하셔도 됩니다.</p>
```

이 버전은 이메일 링크 클릭 대신 인증번호를 게임 화면에 입력하는 방식입니다. 숫자를 복사해 붙여 넣을 수 있고, 모바일 이메일 앱과 게임 브라우저가 달라도 됩니다.
Authentication의 URL Configuration에서 Site URL을 본인의 GitHub Pages 게임 주소로 설정하세요.

Supabase 기본 메일 발송은 프로젝트 팀에 속한 이메일만 대상으로 하며 발송 제한이 있습니다. 본인 계정으로 첫 테스트를 한 뒤, 다른 사람들이 가입하게 하려면 Authentication의 SMTP 설정에서 별도 메일 발송 서비스를 연결해야 합니다. SMTP 비밀번호는 Supabase 설정에만 입력합니다. HTML/config.js에는 넣지 않습니다.

공식 안내:
- https://supabase.com/docs/guides/auth/auth-email-passwordless
- https://supabase.com/docs/guides/auth/auth-smtp
- https://supabase.com/docs/guides/database/postgres/row-level-security

## 4. GitHub에 올리기

압축을 푼 후 index.html과 config.js를 저장소 첫 화면에 함께 업로드합니다. 파일명을 index (1).html로 바꾸지 마세요.
Add file → Upload files → Commit changes를 누릅니다.
Actions의 최신 배포가 성공하면 Settings → Pages → Visit site로 열고 강력 새로고침합니다.
supabase_저장테이블.sql, supabase_계정삭제.sql, README.md는 서버 설정용이므로 사이트에 올릴 필요가 없습니다.

## 5. 직접 확인하기

1. 이메일 인증번호를 받아 로그인합니다. 코드가 틀리면 로그인이 거부되어야 합니다.
2. 홈에서 새 게임을 시작하고 반죽을 구매한 뒤 홈으로 돌아갑니다.
3. 저장 완료를 확인하고 다른 브라우저/휴대폰에서 같은 이메일로 인증합니다.
4. 불러오기를 눌러 돈·일차·설비 등이 이어지는지 확인합니다.
5. 다른 이메일은 별개의 새 가게로 시작하는지 확인합니다.
6. 두 기기에서 동시에 장사하면 먼저 저장한 기기의 기록을 보호하고, 다른 기기에는 충돌 안내가 나오는지 확인합니다.

브라우저를 닫는 순간에는 네트워크 저장 완료를 보장할 수 없습니다. 기기를 옮기기 전에 홈으로 돌아가 저장 완료를 확인해 주세요. 마지막 5초 이내의 변경은 갑작스러운 강제 종료 때 저장되지 않을 수 있습니다.

## 기록 가져오기와 복구

기존과 같은 GitHub Pages 주소, 같은 브라우저를 사용하면 홈의 ‘이전 기록 가져오기 → 이 브라우저의 예전 기록’으로 기존 저장을 가져올 수 있습니다. 서버 기록을 교체하기 전에 확인합니다. 기존 bungeo:v2/bungeo:v1 데이터는 그대로 보존합니다.

계정별 미전송 기록은 bungeo:account:<사용자ID>에 따로 저장합니다. 서버 버전과 같으면 다음 로그인 때 복구할지 묻습니다. 서버 버전이 달라지면 서버 기록을 우선 표시하고 이 기기의 기록을 :recovery 백업에 보관합니다. ‘미전송 기록 백업’으로 JSON을 내려받은 후 필요하면 파일로 가져오세요.

공용 기기에서는 사용 후 로그아웃하세요. 이 버전의 게임 계산은 브라우저에서 수행합니다. 서버 저장은 계정별 접근을 분리하지만, 경쟁 랭킹의 점수 위변조 방지까지 구현한 것은 아닙니다.

## 검증 범위

실제 브라우저에서 Supabase JavaScript SDK와 모의 인증·저장 HTTP 응답으로 로그인, 계정 분리, 저장/복구, 충돌 처리를 검사했습니다. 모바일 크기에서도 로그인/홈 레이아웃을 확인했습니다. PGlite의 PostgreSQL 엔진에서 저장 테이블 생성, 계정별 RLS 접근 제한, 익명 접근 차단, 저장 버전 충돌도 검사했습니다. 아직 사용자 프로젝트의 실제 이메일 발송, 실제 데이터베이스 RLS, 실기기 Safari/Android 검증은 프로젝트 연결 후 수행해야 합니다.

Supabase JS 2.57.4의 브라우저 배포본을 index.html에 포함해 외부 CDN에 의존하지 않습니다. LICENSE-supabase는 해당 라이브러리의 MIT 라이선스입니다.
