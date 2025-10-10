# 🐳 Blog Docker Environment — Multi-Env Setup (Updated 2025-10-10)

이 프로젝트는 **Next.js (Frontend)** + **Laravel (Backend)** + **MariaDB (DB)** + **Nginx (Proxy)** 환경을
Docker 기반으로 개발 및 배포하기 위한 멀티 환경 자동화 구성입니다.

---

## 🚀 주요 특징

- **3단계 환경 분리:** `local`, `development`, `production`
- **환경별 .env 암호화/복호화 자동화**
- **Makefile 기반 관리 명령어**
- **iCloud 백업 지원**
- **상태 확인 명령어 (`make status`)** 포함

---

## 📁 디렉토리 구조

```
blog.backend/      → Laravel Backend
blog.frontend/     → Next.js Frontend
blog.docker/       → Docker + Makefile + Scripts
```

---

## ⚙️ 주요 명령어

### 🔐 환경 파일 관리

| 명령어 | 설명 |
|--------|------|
| `make env-encrypt local` | `.env` → `.env.local.enc` 암호화 |
| `make env-encrypt development` | `.env` → `.env.development.enc` 암호화 |
| `make env-encrypt production` | `.env` → `.env.production.enc` 암호화 |
| `make decrypt-backend local` | 백엔드 `.env.local.enc` 복호화 |
| `make decrypt-frontend local` | 프론트 `.env.local.enc` 복호화 |
| `make backup-env local` | iCloud로 암호화된 .env 파일 백업 |

---

### 🐳 Docker 관리

| 명령어 | 설명 |
|--------|------|
| `make up local` | `.env.local.enc` 복호화 → 컨테이너 빌드/실행 |
| `make down development` | 개발용 컨테이너 종료 및 정리 |
| `make build` | 전체 Docker 이미지 재빌드 |
| `make logs` | 실시간 로그 보기 |
| `make sh-php` | PHP 컨테이너 접속 |
| `make sh-node` | Node 컨테이너 접속 |

---

### 🧩 Laravel / Frontend 유틸리티

| 명령어 | 설명 |
|--------|------|
| `make migrate` | Laravel DB 마이그레이션 |
| `make seed` | Laravel Seeder 실행 |
| `make yarn` | 프론트엔드 Yarn 명령 실행 |
| `make clean` | 모든 .env 및 Docker 볼륨 초기화 |

---

### 🔍 환경 상태 확인

| 명령어 | 설명 |
|--------|------|
| `make status` | Docker + ENV 상태를 이쁘게 출력 |
| `make verify-env` | 컨테이너 내 `APP_ENV` / `NODE_ENV` 출력 확인 |

#### 출력 예시

```
🌍 BLOG SYSTEM STATUS REPORT
──────────────────────────────────────────────
📦 Docker Containers:
NAMES           STATUS          PORTS
blog-nginx      Up 3 minutes    0.0.0.0:4000->80/tcp
blog-node       Up 3 minutes    0.0.0.0:3000->3000/tcp
blog-mariadb    Up 3 minutes    0.0.0.0:3306->3306/tcp

⚙️ Environment Summary:
Backend .env →
../blog.backend/.env (updated: 2025-10-10 19:26)
Frontend .env →
../blog.frontend/.env (updated: 2025-10-10 19:26)

🔑 BLOG_ENV_SECRET:
✅ Set (Length: 44)

🧩 PHP APP_ENV & Node ENV:
APP_ENV=local
NODE_ENV=development

✅ Status check complete.
──────────────────────────────────────────────
```

---

## ☁️ iCloud 백업 경로

- macOS에서 자동으로 아래 위치에 백업됩니다.
  ```bash
  ~/Library/Mobile Documents/com~apple~CloudDocs/blog_envs/
  ```

---

## 💡 환경 변수 (Mac zsh 기준)

`~/.zshrc`에 다음을 추가하세요:

```bash
export BLOG_ENV_SECRET="my-env-secret"
```

---

## 🧠 사용 흐름 요약

```bash
# 1️⃣ 초기 설정
make env-encrypt local

# 2️⃣ 로컬 환경 실행
make up local

# 3️⃣ 상태 확인
make status

# 4️⃣ 종료
make down local
```

---

## 🧱 기본 포트 구성

| 서비스 | 포트 | 설명 |
|---------|------|------|
| Frontend (Next.js) | `3000` | http://localhost:3000 |
| Backend (Laravel + Nginx) | `4000` | http://localhost:4000 |
| Database (MariaDB) | `3306` | 내부 접속용 |

---

## 🧩 주의사항

- `.env` 파일은 Git에 포함되지 않습니다.
- `.env.local.enc` 등 암호화된 파일만 Git에 포함하면 됩니다.
- macOS 기준 `stat` 명령어 포맷(`%Y-%m-%d %H:%M`)로 날짜가 표시됩니다.

---

## ✨ 제작자 메모

> “환경을 바꾸는 힘은 자동화에서 온다.”
> — Runcomm Dev / Blog Platform Project
