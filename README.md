# B1-1 — 시스템 관제 자동화 스크립트 개발

> WSL2 Ubuntu 22.04 LTS 환경에서 SSH 포트 변경, UFW 방화벽, ACL 기반 다중 계정 권한 체계를 구축하고, 시스템 상태 수집 및 로깅을 실시간 처리하는 `monitor.sh` 스크립트를 구현하여 안정적인 서버 운영 환경을 구축하는 프로젝트입니다.

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **과제명** | 시스템 관제 자동화 스크립트 개발 |
| **실행 환경** | Ubuntu 22.04 LTS (WSL2) |
| **구현 언어** | Bash 쉘 스크립트 |
| **최종 산출물** | `monitor.sh`(시스템 상태 수집 및 로깅 스크립트), 수행 내역서(인프라 설정 및 요구사항 검증 결과서) |

---

## 과제 목표

본 과제를 완료하면 다음 역량을 갖추게 됩니다.

1. **기초 보안** — SSH 기본 포트 변경 및 Root 원격 접속 차단의 필요성 이해
2. **네트워크 보안** — UFW를 이용한 최소 포트 허용 방화벽 정책 수립 및 검증
3. **권한 관리** — 역할 기반(Role-based) 계정/그룹 및 ACL을 통한 디렉토리 권한 분리
4. **환경 구성** — 환경 변수 설정으로 실행 환경을 고정하는 목적과 검증 방안
5. **관제 자동화** — 프로세스·포트·리소스 상태 수집 및 로그 기반 문제 역추적 흐름
6. **로그 로테이션** — crontab 스케줄링과 디스크 고갈 방지를 위한 로그 보존 정책

---

## 디렉토리 구조

```
B1-1/
├── Images/
│   ├── Phase1.jpg            # SSH 포트 변경 및 UFW 방화벽 설정 결과 캡처
│   ├── Phase2.jpg            # 계정/그룹 생성 및 ACL 디렉토리 권한 설정 결과 캡처
│   ├── Phase3_1.jpg          # 환경변수 및 API 키 파일 생성 결과 캡처
│   ├── Phase3_2.jpg          # 애플리케이션 실행 및 Boot Sequence 검증 결과 캡처
│   ├── Phase4.jpg            # monitor.sh 스크립트 실행 및 결과 콘솔 출력 캡처
│   └── Phase5.jpg            # crontab 등록 및 매분 로그 자동 누적 결과 캡처
├── Plan/
│   ├── plan.md               # 전체 수행 플랜 (체크리스트 포함)
│   ├── Phase0.md             # WSL 환경 설정 및 준비
│   ├── Phase1.md             # SSH 보안 + 방화벽 설정
│   ├── Phase2.md             # 계정/그룹/ACL 권한 구성
│   ├── Phase3.md             # 앱 실행 환경 구성
│   ├── Phase4.md             # monitor.sh 구현
│   ├── Phase5.md             # crontab 등록 및 검증
│   └── Phase6.md             # 수행 내역서 작성 가이드
├── agent-app.zip             # 제공된 관제 대상 애플리케이션
├── monitor.sh                # 시스템 상태 수집 및 자동 로깅 Bash 스크립트
└── README.md
```

---

## 수행 단계 (Phase)

| 단계 | 문서 | 핵심 내용 |
|:----:|------|-----------|
| **Phase 0** | [Phase0.md](./Plan/Phase0.md) | WSL systemd 활성화, 필수 패키지 설치, 포트 포워딩 테스트 |
| **Phase 1** | [Phase1.md](./Plan/Phase1.md) | SSH 포트 `22 → 20022` 변경, Root 로그인 차단, UFW 방화벽 설정 |
| **Phase 2** | [Phase2.md](./Plan/Phase2.md) | 계정/그룹 생성, 디렉토리 구성, ACL 권한 설정 |
| **Phase 3** | [Phase3.md](./Plan/Phase3.md) | 환경 변수 설정, API 키 생성, 앱 실행 및 Boot Sequence 검증 |
| **Phase 4** | [Phase4.md](./Plan/Phase4.md) | `monitor.sh` 구현 (Health Check, 리소스 수집, 로그 기록, 로테이션) |
| **Phase 5** | [Phase5.md](./Plan/Phase5.md) | crontab 매분 실행 등록 및 로그 자동 누적 검증 |
| **Phase 6** | [Phase6.md](./Plan/Phase6.md) | 수행 내역서 작성 (증거 자료 수집 및 정리 가이드) |

> 전체 체크리스트 및 주의사항은 **[plan.md](./Plan/plan.md)** 를 참고하세요.

---

## 주요 기능 요구사항

### 보안 설정
- SSH 포트: `22 → 20022` 변경 + Root 원격 로그인 차단
- 방화벽(UFW): **TCP 20022 (SSH)**, **TCP 15034 (APP)** 포트만 허용
  - *포트 역할 구분*: **TCP 20022**는 안전한 서버 원격 접속 및 관리를 위한 SSH 서비스 포트이며, **TCP 15034**는 실제 관제 대상 애플리케이션(APP)의 API (Application Programming Interface) 서비스 및 데이터 통신 전용 포트입니다.
  - *UFW vs Firewalld*: **UFW**(우분투 계열 기본)는 설정이 매우 직관적이지만 규칙 반영 시 연결 세션이 끊길 수 있는 반면, **Firewalld**(CentOS 계열 기본)는 영역(Zone) 기반 세부 제어와 서비스 무중단 동적 적용(`--reload`)을 지원합니다.

### 계정 및 권한 체계

| 계정 | 역할 | 소속 그룹 |
|------|------|-----------|
| `agent-admin` | 운영/관리, cron 실행자 | `agent-common`, `agent-core` |
| `agent-dev` | 개발/운영, `monitor.sh` 작성자 | `agent-common`, `agent-core` |
| `agent-test` | QA/테스트 | `agent-common` |

| 디렉토리 | 접근 그룹 | 권한 |
|----------|-----------|------|
| `$AGENT_HOME/upload_files` | `agent-common` | R/W |
| `$AGENT_HOME/api_keys` | `agent-core` | R/W |
| `/var/log/agent-app` | `agent-core` | R/W |

### `monitor.sh` 동작 흐름

```
monitor.sh 실행
├── [Health Check]  프로세스 확인 → 실패 시 exit 1
│                   포트(15034) LISTEN 확인 → 실패 시 exit 1
├── [상태 점검]     방화벽 비활성화 시 [WARNING] 출력
├── [리소스 수집]   CPU / 메모리 / 디스크 사용률 수집
├── [임계값 경고]   CPU > 20% / MEM > 10% / DISK > 80% → [WARNING]
├── [로그 기록]     /var/log/agent-app/monitor.log 에 append
└── [로그 관리]     10MB 초과 시 로테이션, 아카이브 최대 10개 유지
```

**로그 포맷:**
```
[YYYY-MM-DD HH:MM:SS] PID:<앱PID> CPU:<사용률>% MEM:<사용률>% DISK_USED:<사용률>%
```

**로그 예시:**
```
[2026-02-25 14:00:01] PID:48291 CPU:25.3% MEM:9.8% DISK_USED:23%
```

### crontab 자동 실행
```cron
* * * * * /home/agent-admin/agent-app/bin/monitor.sh
```
- `agent-admin` 계정으로 매분 자동 실행
- 실행 후 1~2분 뒤 `/var/log/agent-app/monitor.log` 누적 확인

---

## 빠른 시작

### 1. 환경 준비 (Phase 0)
```bash
# WSL systemd 활성화
sudo sh -c 'echo -e "[boot]\nsystemd=true" > /etc/wsl.conf'
# (Windows PowerShell에서) wsl --shutdown 후 재시작

# 필수 패키지 설치
sudo apt update && sudo apt install -y openssh-server ufw acl net-tools bc unzip
```

### 2. 앱 배포 (Phase 3)
```bash
# agent-app.zip 압축 해제 후 AGENT_HOME에 배치
unzip agent-app.zip -d /home/agent-admin/agent-app

# 환경 변수 설정 (~/.bashrc에 추가)
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
```

### 3. 앱 실행 검증
```bash
# agent-admin 계정으로 실행 (Root 절대 금지)
su - agent-admin
cd $AGENT_HOME
./agent-app-linux-x86   # 또는 agent-app-linux-arm64 (ARM 환경)
```

**정상 출력 예시:**
```
Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
[2/5] Verifying Environment Variables     [OK]
[3/5] Checking Required Files             [OK]
[4/5] Checking Port Availability          [OK]
[5/5] Verifying Log Permission            [OK]
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
```

---

## 주의 사항

- **절대 금지** — 앱 실행 시 Root 계정 사용 불가. `agent-admin` 계정으로만 실행
- **구현 언어** — `monitor.sh`는 반드시 Bash 쉘 스크립트로만 작성 (Python 등 타 언어 불가)
- **SSH 포트 변경 시** — 방화벽 설정 전 현재 SSH 세션을 유지할 것 (연결이 끊기면 접속 불가)
- **Docker/WSL 환경** — 컨테이너 재시작 시 환경 변수 초기화 주의, `~/.bashrc`에 반드시 등록

---

## 최종 제출물

| # | 산출물 | 설명 |
|---|--------|------|
| 1 | **수행 내역서** | 모든 설정 명령어 내역 + 필수 증거 스크린샷 |
| 2 | **`monitor.sh`** | 시스템 상태 수집 및 자동 로깅 Bash 스크립트 |
