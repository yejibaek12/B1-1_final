# B1-1 과제 수행 플랜: 시스템 관제 자동화 스크립트 개발

## 단계별 상세 문서 (순서대로 진행)

| 단계 | 문서 | 내용 |
|------|------|------|
| Phase 0 | [Phase0.md](./Phase0.md) | 가상 머신(VM) 설치 및 초기 네트워크 포트 포워딩 설정 |
| Phase 1 | [Phase1.md](./Phase1.md) | SSH 포트 변경, Root 로그인 차단, UFW 방화벽 설정 |
| Phase 2 | [Phase2.md](./Phase2.md) | 계정/그룹 생성, 디렉토리 구성, ACL 권한 설정 |
| Phase 3 | [Phase3.md](./Phase3.md) | 환경 변수 설정, API 키 생성, 앱 실행 및 Boot Sequence 검증 |
| Phase 4 | [Phase4.md](./Phase4.md) | `monitor.sh` 구현 (코드 전체 포함) |
| Phase 5 | [Phase5.md](./Phase5.md) | crontab 등록 및 자동 실행 검증 |
| Phase 6 | [Phase6.md](./Phase6.md) | 수행 내역서 작성 (증거 자료 수집 가이드) |

---


## 개요

| 항목 | 내용 |
|------|------|
| 과제명 | 시스템 관제 자동화 스크립트 개발 |
| 환경 | Ubuntu 22.04 LTS (Docker 컨테이너 또는 VM) |
| 언어 | Bash 쉘 스크립트 |
| 최종 산출물 | `monitor.sh`, 수행 내역서 |

---

## 단계별 수행 계획

### Phase 1. 환경 확인 및 기초 보안 설정

> 목표: SSH 포트 변경, Root 로그인 차단, 방화벽 설정

#### 1-1. SSH 설정 변경
- [ ] `/etc/ssh/sshd_config` 파일에서 포트를 `22 → 20022`로 변경
- [ ] `PermitRootLogin no` 설정 확인 및 수정
- [ ] `sshd` 재시작: `sudo systemctl restart sshd`
- [ ] 검증: `ss -tulnp | grep 20022` → sshd가 20022 포트에서 LISTEN 중인지 확인

#### 1-2. 방화벽 설정 (UFW 사용)
- [ ] UFW 활성화: `sudo ufw enable`
- [ ] 기본 정책 설정: `sudo ufw default deny incoming`
- [ ] TCP 20022 허용: `sudo ufw allow 20022/tcp`
- [ ] TCP 15034 허용: `sudo ufw allow 15034/tcp`
- [ ] 검증: `sudo ufw status` → 두 포트만 허용되어 있는지 확인

---

### Phase 2. 계정 / 그룹 / 디렉토리 권한 구성

> 목표: 역할 기반 계정·그룹 생성 및 ACL 적용

#### 2-1. 그룹 생성
- [ ] `sudo groupadd agent-common`
- [ ] `sudo groupadd agent-core`

#### 2-2. 계정 생성 및 그룹 배정
- [ ] `sudo useradd -m -s /bin/bash agent-admin`
- [ ] `sudo useradd -m -s /bin/bash agent-dev`
- [ ] `sudo useradd -m -s /bin/bash agent-test`
- [ ] `agent-common` 그룹에 세 계정 모두 추가:
  ```bash
  sudo usermod -aG agent-common agent-admin
  sudo usermod -aG agent-common agent-dev
  sudo usermod -aG agent-common agent-test
  ```
- [ ] `agent-core` 그룹에 admin, dev 추가:
  ```bash
  sudo usermod -aG agent-core agent-admin
  sudo usermod -aG agent-core agent-dev
  ```
- [ ] 검증: `id agent-admin`, `id agent-dev`, `id agent-test`

#### 2-3. 디렉토리 구조 생성
- [ ] `AGENT_HOME` 결정: `/home/agent-admin/agent-app`
- [ ] 디렉토리 생성:
  ```bash
  sudo mkdir -p /home/agent-admin/agent-app/upload_files
  sudo mkdir -p /home/agent-admin/agent-app/api_keys
  sudo mkdir -p /home/agent-admin/agent-app/bin
  sudo mkdir -p /var/log/agent-app
  ```

#### 2-4. ACL 권한 설정
- [ ] `upload_files`: `agent-common` 그룹 R/W, 외부 차단:
  ```bash
  sudo chown agent-admin:agent-common /home/agent-admin/agent-app/upload_files
  sudo chmod 770 /home/agent-admin/agent-app/upload_files
  sudo setfacl -m g:agent-common:rwx /home/agent-admin/agent-app/upload_files
  ```
- [ ] `api_keys`: `agent-core` 그룹 R/W, 외부 차단:
  ```bash
  sudo chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys
  sudo chmod 770 /home/agent-admin/agent-app/api_keys
  sudo setfacl -m g:agent-core:rwx /home/agent-admin/agent-app/api_keys
  ```
- [ ] `/var/log/agent-app`: `agent-core` 그룹 R/W:
  ```bash
  sudo chown agent-admin:agent-core /var/log/agent-app
  sudo chmod 770 /var/log/agent-app
  sudo setfacl -m g:agent-core:rwx /var/log/agent-app
  ```
- [ ] 검증: `ls -l`, `getfacl` 명령어로 각 디렉토리 권한 확인

---

### Phase 3. 애플리케이션 실행 환경 구성

> 목표: 환경 변수 설정, API 키 생성, 앱 실행 및 Boot Sequence 검증

#### 3-1. 환경 변수 설정
- [ ] `agent-admin` 계정의 `~/.bashrc`에 추가:
  ```bash
  export AGENT_HOME=/home/agent-admin/agent-app
  export AGENT_PORT=15034
  export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
  export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
  export AGENT_LOG_DIR=/var/log/agent-app
  ```
- [ ] 적용: `source ~/.bashrc`
- [ ] 검증: `echo $AGENT_HOME` 등 각 변수 출력 확인

#### 3-2. API 키 파일 생성
- [ ] `echo "agent_api_key_test" > $AGENT_HOME/api_keys/t_secret.key`
- [ ] 권한 설정: `chmod 640 $AGENT_HOME/api_keys/t_secret.key`

#### 3-3. 앱 배포 및 실행 검증
- [ ] `agent-app.zip` 압축 해제 후 바이너리를 `$AGENT_HOME`에 배치
- [ ] 실행 권한 부여: `chmod +x agent-app-linux-x86` (또는 arm64)
- [ ] `agent-admin` 계정으로 실행 (Root 절대 금지):
  ```bash
  su - agent-admin
  cd $AGENT_HOME
  ./agent-app-linux-x86
  ```
- [ ] Boot Sequence 5단계 모두 `[OK]` 출력 및 `Agent READY` 문구 확인
- [ ] 포트 확인: `ss -tulnp | grep 15034` → `0.0.0.0:15034` LISTEN 상태 확인

---

### Phase 4. `monitor.sh` 스크립트 구현

> 목표: 시스템 상태 수집 및 자동 로깅 스크립트 작성

#### 4-1. 스크립트 기본 구조
```
$AGENT_HOME/bin/monitor.sh
├── Health Check (프로세스 & 포트 검사) → 실패 시 exit 1
├── 방화벽 상태 점검 → 비활성화 시 [WARNING] 출력
├── 리소스 수집 (CPU, MEM, DISK)
├── 임계값 경고 출력 (CPU>20%, MEM>10%, DISK>80%)
├── 로그 파일 기록 (/var/log/agent-app/monitor.log)
└── 로그 용량 관리 (최대 10MB, 아카이브 10개 유지)
```

#### 4-2. 세부 구현 항목
- [ ] **프로세스 검사**: `pgrep -f agent-app-linux` 으로 PID 획득, 없으면 `exit 1`
- [ ] **포트 검사**: `ss -tulnp | grep :15034` 로 LISTEN 상태 확인, 없으면 `exit 1`
- [ ] **방화벽 상태**: `ufw status | grep -i active` 로 확인 → 비활성화 시 `[WARNING]` 출력
- [ ] **CPU 사용률**: `top -bn1 | grep "Cpu(s)"` 파싱 또는 `vmstat` 활용
- [ ] **메모리 사용률**: `free | grep Mem` 파싱 → `used/total * 100`
- [ ] **디스크 사용률**: `df / | awk 'NR==2 {print $5}'` → `%` 제거
- [ ] **로그 기록**: 아래 포맷으로 `/var/log/agent-app/monitor.log`에 append:
  ```
  [YYYY-MM-DD HH:MM:SS] PID:<앱PID> CPU:<사용률>% MEM:<사용률>% DISK_USED:<사용률>%
  ```
- [ ] **로그 용량 관리**: 10MB 초과 시 로테이션, 아카이브 10개 유지

#### 4-3. 파일 권한 설정
- [ ] 소유자 `agent-dev` / 그룹 `agent-core` / 권한 `750`:
  ```bash
  sudo chown agent-dev:agent-core $AGENT_HOME/bin/monitor.sh
  sudo chmod 750 $AGENT_HOME/bin/monitor.sh
  ```
- [ ] 검증: `agent-admin` 계정에서 실행 가능한지 확인

---

### Phase 5. crontab 등록 및 자동 실행 검증

> 목표: 매분 자동 실행 등록 및 로그 누적 확인

#### 5-1. crontab 등록
- [ ] `agent-admin` 계정으로 `crontab -e` 실행
- [ ] 아래 라인 추가:
  ```cron
  * * * * * /home/agent-admin/agent-app/bin/monitor.sh
  ```

#### 5-2. 자동 실행 검증
- [ ] 1~2분 대기 후 로그 파일 확인: `tail -f /var/log/agent-app/monitor.log`
- [ ] 로그 라인이 매분 누적되는지 확인
- [ ] `wc -l /var/log/agent-app/monitor.log` 로 라인 수 증가 확인

---

### Phase 6. (선택) 보너스 과제 구현

#### 보너스 1 – `report.sh` 요약 리포트 스크립트
- [ ] `monitor.log` 파싱하여 CPU, MEM, DISK 평균/최대/최소값 및 데이터 건수 계산
- [ ] (선택) 시작/종료 시간 인자 지원: `./report.sh "2026-06-01 00:00" "2026-06-01 23:59"`

#### 보너스 2 – 시간 기반 로그 아카이빙 정책
- [ ] 7일 경과 `.log` 파일 `gzip` 압축
- [ ] 압축 파일을 `/var/log/monitor/agent-app/archive/`로 이동
- [ ] 30일 경과 `.gz` 파일 삭제
- [ ] 예외 처리: 디렉토리 미존재, 권한 부족, 대상 파일 0개 시 경고 후 안전 종료

---

### Phase 7. 수행 내역서 작성

> 목표: 모든 설정 내역과 증거 자료를 문서로 정리

- [ ] SSH 포트 변경 설정 캡처 (`sshd_config` 내용 + `ss -tulnp` 결과)
- [ ] 방화벽 설정 캡처 (`ufw status` 결과)
- [ ] 계정/그룹 생성 캡처 (`id` 명령 결과)
- [ ] 디렉토리 권한 캡처 (`ls -l`, `getfacl` 결과)
- [ ] Boot Sequence `[OK]` 5단계 출력 캡처
- [ ] `monitor.sh` 실행 결과 콘솔 캡처
- [ ] `monitor.log` 누적 로그 라인 캡처 (최근 수 줄)
- [ ] crontab 등록 내용 및 1분 후 로그 증가 캡처

---

## 체크리스트 요약

| # | 항목 | 상태 |
|---|------|------|
| 1 | SSH 포트 변경 + Root 로그인 차단 | `[ ]` |
| 2 | 방화벽(UFW) 설정 | `[ ]` |
| 3 | 계정/그룹 생성 및 권한 배정 | `[ ]` |
| 4 | 디렉토리 구조 및 ACL 권한 설정 | `[ ]` |
| 5 | 환경 변수 설정 | `[ ]` |
| 6 | API 키 파일 생성 | `[ ]` |
| 7 | 앱 실행 및 Boot Sequence 검증 | `[ ]` |
| 8 | `monitor.sh` 구현 | `[ ]` |
| 9 | `monitor.sh` 권한 설정 | `[ ]` |
| 10 | crontab 등록 및 자동 실행 확인 | `[ ]` |
| 11 | (보너스) `report.sh` 구현 | `[ ]` |
| 12 | (보너스) 시간 기반 아카이빙 구현 | `[ ]` |
| 13 | 수행 내역서 작성 | `[ ]` |

---

## 주의 사항

> **CAUTION**
> - 앱 실행 시 **절대 Root 계정 사용 금지** — `agent-admin` 계정으로만 실행
> - `monitor.sh`는 **Bash 쉘 스크립트**로만 작성 (Python 등 타 언어 사용 불가)
> - SSH 포트 변경 후 방화벽 설정 전에 현재 SSH 세션 유지할 것 (연결 끊기면 접속 불가)

> **TIP**
> - Docker 환경이라면 컨테이너 재시작 시 환경 변수가 초기화될 수 있으므로 `~/.bashrc`에 반드시 등록
> - `monitor.sh` 디버깅 시 `bash -x monitor.sh` 명령으로 실행 흐름 추적 가능
> - crontab 등록 후 `/var/log/syslog`에서 cron 실행 로그 확인 가능: `grep CRON /var/log/syslog`
