# 🐳 My 블러그 프로젝트 — Docker 개발 환경 가이드

이 환경은 **Next.js(Frontend)** + **Laravel(Backend)** + **MariaDB** 로 구성된
개인 블로그 프로젝트의 **로컬/운영 통합 Docker 개발 세트**입니다.

`.env` 파일은 **암호화된 형태로 iCloud 에 백업**되고,
`make up local` 명령만으로 자동 복호화 및 실행이 가능합니다.

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
| 🔐 `.env` 암호화 | OpenSSL AES-256 암호화 (`.env.local.enc`, `.env.production.enc`) |
| ☁️ iCloud 백업 | 암호화된 `.env` 자동 백업 |
| 🧪 Verify | 컨테이너 내부 `.env` 반영 상태 자동 확인 |
| 🧰 Makefile | 모든 명령어를 `make` 한 줄로 실행 가능 |

---

## ⚙️ 초기 세팅

### 1. 환경변수 키 등록

맥에서 Zsh(`.zshrc` 또는 `.local.zshrc`)에 아래를 추가합니다.

```bash
export BLOG_ENV_SECRET="my-secret"
```

> 이 키는 `.env` 암호화/복호화 시 사용됩니다.
> iCloud 동기화 중인 모든 Mac 에 동일한 키를 추가해야 합니다.

적용 후 터미널 재시작:
```bash
source ~/.zshrc
```

---

## 🧩 Makefile 주요 명령어

### 🔹 컨테이너 실행

| 명령어 | 설명 |
|--------|------|
| `make up local` | 로컬 개발용 컨테이너 실행 |
| `make up development` | 개발 서버용 실행 |
| `make up production` | 배포용 실행 |

> 실행 시 `.env.{ENV}.enc` 파일이 자동 복호화되어 `.env` 로 반영됩니다.

---

### 🔹 컨테이너 중지

| 명령어 | 설명 |
|--------|------|
| `make down local` | 로컬 환경 중지 및 정리 |
| `make down production` | 운영 환경 중지 및 정리 |

---

### 🔹 `.env` 관리

| 명령어 | 설명 |
|--------|------|
| `make env-encrypt ENV=local` | `.env` → `.env.local.enc` 암호화 |
| `make env-encrypt ENV=production` | `.env` → `.env.production.enc` 암호화 |
| `make decrypt-backend ENV=local` | 백엔드 `.env.local.enc` 복호화 |
| `make decrypt-frontend ENV=local` | 프론트 `.env.local.enc` 복호화 |
| `make backup-env ENV=local` | 암호화된 `.env.*.enc` 파일 iCloud로 백업 |

---

### 🔹 컨테이너 내부 진입

| 명령어 | 설명 |
|--------|------|
| `make sh-php` | PHP 컨테이너 진입 (`/var/www/html`) |
| `make sh-node` | Node 컨테이너 진입 (`/usr/src/app`) |

---

### 🔹 Laravel / Yarn 관리

| 명령어 | 설명 |
|--------|------|
| `make migrate` | Laravel DB 마이그레이션 실행 |
| `make seed` | Seeder 실행 |
| `make yarn` | Yarn 명령 프록시 실행 (`yarn install` 등) |

---

### 🔹 환경 검증

| 명령어 | 설명 |
|--------|------|
| `make verify-env` | 컨테이너 내부 `.env` 파일 내용 일부 표시 |
| `make clean` | 컨테이너 및 볼륨 완전 정리 (`.env` 유지) |

---

## 🧠 동작 순서 요약

1️⃣ `.env.{ENV}.enc` 복호화 → `.env` 생성
2️⃣ Docker Compose 빌드 및 컨테이너 실행
3️⃣ 실행 후 `.env` 파일 자동 참조
4️⃣ 종료(`make down`) 시 컨테이너만 정리

---

## ☁️ iCloud 백업 경로

암호화된 `.env` 백업 파일은 자동으로 아래 경로에 저장됩니다:
```
~/Library/Mobile Documents/com~apple~CloudDocs/blog_envs/
```

| 파일명 | 내용 |
|--------|------|
| `blog_backend.local.enc` | 백엔드 로컬 환경 |
| `blog_frontend.production.enc` | 프론트 운영 환경 |

---

## 🔍 예시 워크플로우

```bash
# 1. 로컬 환경 실행
make up local

# 2. Laravel DB 마이그레이션
make migrate

# 3. .env 정상 반영 확인
make verify-env

# 4. 중지
make down local

# 5. 수정된 .env 암호화
make env-encrypt ENV=production

# 6. iCloud 백업
make backup-env ENV=production
```

---

## 🧹 문제 해결

| 문제 | 해결 방법 |
|------|-------------|
| `.env` 디렉토리로 잘못 생성됨 | `.env` 삭제 후 `make up local` 재실행 |
| `.env` 복호화 실패 | `BLOG_ENV_SECRET` 값 확인 후 재시도 |
| DB 연결 오류 | `.env` 내 DB_HOST 값이 `db` 인지 확인 |
| 컨테이너 빌드 실패 | `make clean` → `make up local` 로 초기화 |

---

## 🧾 License

MIT © 2025 [psmever]
개인 프로젝트용으로 자유롭게 수정/배포 가능합니다.
