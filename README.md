# 🐳 My 블러그 프로젝트 — Docker 개발 환경 가이드 (인자 기반 버전)

이 환경은 **Next.js(Frontend)** + **Laravel(Backend)** + **MariaDB** 로 구성된
개인 블로그 프로젝트의 **로컬/운영 통합 Docker 개발 세트**입니다.

`.env` 파일은 **AES-256 방식으로 암호화되어 iCloud에 백업**되며,
`make up local` 명령만으로 자동 복호화 후 실행이 가능합니다.

---

## 📁 디렉토리 구조

```
blog.backend/      # Laravel 백엔드
blog.frontend/     # Next.js 프론트엔드
blog.docker/       # Docker 설정 및 관리 스크립트
```

---

## 🚀 주요 기능

| 기능 | 설명 |
|------|------|
| 🧩 Docker Compose | Laravel, Nginx, Node, MariaDB 자동 구성 |
| 🔐 `.env` 암호화 | OpenSSL AES-256 기반 (`.env.local.enc`, `.env.production.enc`) |
| ☁️ iCloud 백업 | 암호화된 `.env` 자동 백업 |
| 🧪 Verify | 컨테이너 내부 `.env` 반영 상태 자동 확인 |
| 🧰 Makefile | 모든 명령어를 `make` 한 줄로 실행 가능 |

---

## ⚙️ 초기 세팅

### 1️⃣ 환경 변수 등록 (Mac Zsh)

`.zshrc` 또는 `.local.zshrc` 에 아래를 추가하세요.

```bash
export BLOG_ENV_SECRET="my-env-secret"
```

> 이 키는 `.env` 암호화/복호화 시 사용됩니다.
> iCloud와 동기화된 모든 Mac에 동일한 키를 설정해야 합니다.

적용:
```bash
source ~/.zshrc
```

---

## 🧩 Makefile 주요 명령어

### 🔹 컨테이너 실행 / 종료

| 명령어 | 설명 |
|--------|------|
| `make up local` | 로컬 개발용 실행 |
| `make up development` | 개발 서버용 실행 |
| `make up production` | 운영용 실행 |
| `make down local` | 로컬 컨테이너 종료 |
| `make down production` | 운영 컨테이너 종료 |

---

### 🔹 `.env` 암호화 / 복호화 / 백업

| 명령어 | 설명 |
|--------|------|
| `make env-encrypt local` | `.env` → `.env.local.enc` 암호화 |
| `make env-encrypt production` | `.env` → `.env.production.enc` 암호화 |
| `make decrypt-backend local` | 백엔드 `.env.local.enc` 복호화 |
| `make decrypt-frontend production` | 프론트 `.env.production.enc` 복호화 |
| `make backup-env local` | 암호화된 `.env.local.enc` iCloud 백업 |

> 🔐 모든 암호화·복호화는 `BLOG_ENV_SECRET` 키를 기반으로 수행됩니다.

---

### 🔹 컨테이너 내부 접근

| 명령어 | 설명 |
|--------|------|
| `make sh-php` | PHP 컨테이너 접속 (`/var/www/html`) |
| `make sh-node` | Node 컨테이너 접속 (`/usr/src/app`) |

---

### 🔹 Laravel / Yarn

| 명령어 | 설명 |
|--------|------|
| `make migrate` | Laravel DB 마이그레이션 실행 |
| `make seed` | Seeder 실행 |
| `make yarn` | Yarn 명령 실행 (ex. `install`, `dev` 등) |

---

### 🔹 환경 검증

| 명령어 | 설명 |
|--------|------|
| `make verify-env` | PHP/Node 컨테이너 내 `.env` 반영 여부 확인 |
| `make clean` | 전체 컨테이너 및 볼륨 초기화 (환경 유지) |

---

## 🧠 실행 순서 예시

```bash
# 1. 로컬 개발 환경 실행
make up local

# 2. Laravel 마이그레이션
make migrate

# 3. 컨테이너 내부 .env 확인
make verify-env

# 4. 종료
make down local

# 5. 수정된 .env 암호화
make env-encrypt production

# 6. iCloud 백업
make backup-env production
```

---

## ☁️ iCloud 백업 경로

암호화된 `.env` 백업 파일은 자동으로 아래에 저장됩니다:

```
~/Library/Mobile Documents/com~apple~CloudDocs/blog_envs/
```

| 파일명 | 설명 |
|--------|------|
| `blog_backend.local.enc` | 백엔드 로컬 환경 |
| `blog_frontend.production.enc` | 프론트 운영 환경 |

---

## 🧹 문제 해결

| 문제 | 원인 / 해결책 |
|------|----------------|
| `.env` 디렉토리로 생성됨 | `.env` 디렉토리 삭제 후 `make up local` 재실행 |
| `.env` 복호화 실패 | `BLOG_ENV_SECRET` 키값 확인 |
| DB 연결 실패 | `.env` 내 `DB_HOST=db` 확인 |
| 빌드 실패 | `make clean` → `make up local` 로 초기화 |

---

## 🧾 License

MIT © 2025 [psmever]
개인 프로젝트용으로 자유롭게 수정 및 배포 가능합니다.
