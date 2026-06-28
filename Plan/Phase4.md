# Phase 4. `monitor.sh` 스크립트 구현

> **목표**: `$AGENT_HOME/bin/monitor.sh` 파일을 작성하여 Health Check, 리소스 수집, 로그 기록, 로그 용량 관리까지 구현합니다.

---

## 4-1. 스크립트 파일 생성

`agent-dev` 계정으로 전환하여 스크립트를 작성합니다:

```bash
sudo su - agent-dev
```

파일 생성:

```bash
nano /home/agent-admin/agent-app/bin/monitor.sh
```

---

## 4-2. 스크립트 전체 코드

아래 내용을 그대로 붙여넣습니다:

```bash
#!/bin/bash

# ============================================================
# monitor.sh - 시스템 관제 자동화 스크립트
# 소유자: agent-dev / 그룹: agent-core / 권한: 750
# ============================================================

LOG_FILE="/var/log/agent-app/monitor.log"
APP_NAME="agent-app-linux"
APP_PORT=15034
LOG_MAX_SIZE=$((10 * 1024 * 1024))   # 10MB (bytes)
LOG_MAX_ARCHIVE=10

echo "====== SYSTEM MONITOR RESULT ======"
echo ""

# ============================================================
# [HEALTH CHECK] 프로세스 및 포트 검사
# ============================================================
echo "[HEALTH CHECK]"

# 프로세스 검사
APP_PID=$(pgrep -f "$APP_NAME")
if [ -z "$APP_PID" ]; then
    echo "Checking process '$APP_NAME'... [FAIL] Process not running"
    exit 1
else
    echo "Checking process '$APP_NAME'... [OK] (PID: $APP_PID)"
fi

# 포트 검사
PORT_CHECK=$(ss -tulnp | grep ":${APP_PORT}")
if [ -z "$PORT_CHECK" ]; then
    echo "Checking port ${APP_PORT}... [FAIL] Port not listening"
    exit 1
else
    echo "Checking port ${APP_PORT}... [OK]"
fi

echo ""

# ============================================================
# [FIREWALL CHECK] 방화벽 상태 점검
# ============================================================
UFW_STATUS=$(sudo ufw status 2>/dev/null | grep -i "Status: active")
if [ -z "$UFW_STATUS" ]; then
    echo "[WARNING] Firewall (UFW) is not active!"
fi

# ============================================================
# [RESOURCE MONITORING] 리소스 수집
# ============================================================
echo "[RESOURCE MONITORING]"

# CPU 사용률 (idle % 를 100에서 빼서 사용률 계산)
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%,')
CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc)

# 메모리 사용률
MEM_TOTAL=$(free | grep Mem | awk '{print $2}')
MEM_USED=$(free | grep Mem | awk '{print $3}')
MEM_USAGE=$(echo "scale=1; $MEM_USED / $MEM_TOTAL * 100" | bc)

# 디스크 사용률 (루트 파티션)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

echo "CPU Usage  : ${CPU_USAGE}%"
echo "MEM Usage  : ${MEM_USAGE}%"
echo "DISK Used  : ${DISK_USAGE}%"
echo ""

# ============================================================
# [WARNING] 임계값 초과 경고
# ============================================================
CPU_INT=$(echo "$CPU_USAGE" | awk -F. '{print $1}')
MEM_INT=$(echo "$MEM_USAGE" | awk -F. '{print $1}')

if [ "$CPU_INT" -gt 20 ]; then
    echo "[WARNING] CPU threshold exceeded (${CPU_USAGE}% > 20%)"
fi

if [ "$MEM_INT" -gt 10 ]; then
    echo "[WARNING] MEM threshold exceeded (${MEM_USAGE}% > 10%)"
fi

if [ "$DISK_USAGE" -gt 80 ]; then
    echo "[WARNING] DISK threshold exceeded (${DISK_USAGE}% > 80%)"
fi

# ============================================================
# [LOG] 로그 용량 관리 (10MB 초과 시 로테이션)
# ============================================================
if [ -f "$LOG_FILE" ]; then
    CURRENT_SIZE=$(stat -c%s "$LOG_FILE")
    if [ "$CURRENT_SIZE" -ge "$LOG_MAX_SIZE" ]; then
        # 가장 오래된 아카이브 삭제 후 번호 순서 밀기
        for i in $(seq $((LOG_MAX_ARCHIVE - 1)) -1 1); do
            if [ -f "${LOG_FILE}.${i}" ]; then
                mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i + 1))"
            fi
        done
        # 현재 로그를 .1로 이동
        mv "$LOG_FILE" "${LOG_FILE}.1"
        # 최대 개수 초과 아카이브 삭제
        if [ -f "${LOG_FILE}.$((LOG_MAX_ARCHIVE + 1))" ]; then
            rm -f "${LOG_FILE}.$((LOG_MAX_ARCHIVE + 1))"
        fi
    fi
fi

# ============================================================
# [LOG] 로그 파일에 기록
# ============================================================
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOG_LINE="[${TIMESTAMP}] PID:${APP_PID} CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USAGE}%"

echo "$LOG_LINE" >> "$LOG_FILE"
echo ""
echo "[INFO] Log appended: $LOG_FILE"
echo "======================================"
```

저장 후 종료 (`Ctrl+O` → `Ctrl+X`)

---

## 4-3. 스크립트 권한 설정

`agent-dev` 작업이 끝났으면 `root` 또는 `sudo` 권한이 있는 계정으로 전환:

```bash
exit  # agent-dev 세션 종료
```

권한 설정:

```bash
# 소유자: agent-dev / 그룹: agent-core
sudo chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh

# 권한: 750 (rwxr-x---)
sudo chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
```

**검증:**
```bash
sudo ls -l /home/agent-admin/agent-app/bin/monitor.sh
```

**예상 출력:**
```
-rwxr-x--- 1 agent-dev agent-core ... monitor.sh
```

---

## 4-4. 스크립트 실행 테스트

> ⚠️ 앱(`agent-app-linux-x86`)이 실행 중이어야 합니다. 실행 중이 아니라면 먼저 백그라운드로 실행합니다:
> ```bash
> sudo su - agent-admin -c "nohup /home/agent-admin/agent-app/agent-app-linux-x86 > /dev/null 2>&1 &"
> ```
> 
> 💡 **명령어 구조 및 옵션 상세 설명:**
> 1. **`sudo su - agent-admin -c "[명령어]"`**
>    - **`su - agent-admin`**: `agent-admin` 계정으로 전환하되, 뒤에 붙은 `-` 기호 덕분에 해당 계정의 로그인 환경변수(Phase 3에서 설정한 `~/.bashrc`)를 완전히 새로 로드합니다.
>    - **`-c` (Command)**: 계정을 직접 로그인해서 터미널을 열어두는 것이 아니라, 뒤에 오는 따옴표 안의 명령어를 **해당 계정 권한으로 한 번만 실행**하고 바로 빠져나옵니다.
> 2. **`nohup`** (No Hang Up)
>    - 터미널 창을 끄거나 SSH 접속이 끊어지더라도 실행한 프로세스가 **종료되지 않고 계속 실행 상태를 유지**하도록 만듭니다.
> 3. **`> /dev/null 2>&1`** (출력 리다이렉션)
>    - **`> /dev/null`**: 프로그램의 일반 출력(stdout)을 화면에 띄우거나 파일로 저장하지 않고 무시(휴지통으로 버림)합니다.
>    - **`2>&1`**: 에러 출력(stderr, 번호 2)을 일반 출력(stdout, 번호 1)이 가는 곳으로 보냅니다. 즉, 일반 출력과 에러 출력 모두 휴지통(`/dev/null`)으로 버려 터미널 콘솔을 깨끗하게 유지합니다.
> 4. **맨 끝의 `&`** (백그라운드 실행)
>    - 이 프로그램을 백그라운드로 실행시켜, 프로그램이 켜져 있는 동안에도 터미널에 다른 명령어를 입력할 수 있도록 제어권을 돌려받습니다.

`agent-admin` 계정으로 실행 (`agent-core` 그룹 소속이므로 실행 권한 있음):

```bash
sudo su - agent-admin
/home/agent-admin/agent-app/bin/monitor.sh
```

**예상 출력:**
```
====== SYSTEM MONITOR RESULT ======

[HEALTH CHECK]
Checking process 'agent-app-linux'... [OK] (PID: 48291)
Checking port 15034... [OK]

[RESOURCE MONITORING]
CPU Usage  : 5.3%
MEM Usage  : 8.2%
DISK Used  : 23%

[INFO] Log appended: /var/log/agent-app/monitor.log
======================================
```

**로그 기록 확인:**
```bash
cat /var/log/agent-app/monitor.log
```

**예상 출력:**
```
[2026-06-28 23:30:01] PID:48291 CPU:5.3% MEM:8.2% DISK_USED:23%
```

---

## 4-5. sudo 권한 설정 (UFW 상태 확인용)

`monitor.sh` 내에서 `sudo ufw status`를 실행하려면 `agent-admin`이 패스워드 없이 ufw 명령을 실행할 수 있어야 합니다:

```bash
sudo visudo
```

파일 맨 아래에 추가:

```
agent-admin ALL=(ALL) NOPASSWD: /usr/sbin/ufw status
```

> 💡 **`sudoers` 설정 구문 상세 설명:**
> - **`agent-admin`**: 이 규칙을 적용할 대상 사용자 계정입니다.
> - **`ALL=`**: 모든 컴퓨터(호스트) 접속 환경에서 이 규칙을 적용합니다.
> - **`(ALL)`**: 임의의 다른 계정 권한으로 이 명령을 대행해서 실행할 수 있게 합니다.
> - **`NOPASSWD:`**: 이 설정을 적용한 명령어를 `sudo`로 실행할 때 **비밀번호 입력을 요구하지 않고 즉시 실행**합니다.
>   - **이유**: `monitor.sh`는 매분 백그라운드(`cron` 스케줄러)에서 자동으로 돌아갑니다. `cron`은 사용자 입력을 받을 수 없으므로 비밀번호 창이 뜨면 명령어 실행에 실패하게 됩니다. 이를 해결하기 위해 비밀번호 면제 옵션을 줍니다.
> - **`/usr/sbin/ufw status`**: 비밀번호 없이 실행할 수 있는 **정확한 명령어의 절대 경로**입니다.
>   - **최소 권한 정책(Least Privilege)**: 보안을 위해 `ufw` 전체 명령어가 아니라 상태를 조회하는 `ufw status`에만 비밀번호 면제를 주었습니다. 따라서 `agent-admin` 계정은 비밀번호 없이 방화벽 상태 조회는 할 수 있지만, 방화벽을 강제로 끄는 등(`sudo ufw disable`)의 행위는 비밀번호 없이는 차단되므로 안전합니다.
>   - *참고: `which ufw` 명령어를 쳤을 때 나타나는 실행 바이너리의 절대 경로를 명시해주어야 보안 시스템(sudoers)이 제대로 인식합니다.*

---

## 완료 체크리스트

- [ ] `monitor.sh` 파일 생성 완료 (경로: `/home/agent-admin/agent-app/bin/monitor.sh`)
- [ ] 소유자 `agent-dev` / 그룹 `agent-core` / 권한 `750` 설정 완료
- [ ] `agent-admin` 계정에서 실행 성공 확인
- [ ] Health Check `[OK]` (프로세스 + 포트) 확인
- [ ] 리소스(CPU/MEM/DISK) 수집 확인
- [ ] `/var/log/agent-app/monitor.log` 로그 기록 확인

---

## 증거 자료 수집 (수행 내역서용)

```bash
# 스크립트 권한 확인
ls -l /home/agent-admin/agent-app/bin/monitor.sh

# 실행 결과 (콘솔 캡처)
sudo su - agent-admin -c "/home/agent-admin/agent-app/bin/monitor.sh"

# 로그 파일 내용 확인
tail -5 /var/log/agent-app/monitor.log
```

---

⬅️ **이전 단계**: [Phase 3 - 앱 실행 환경 구성](./Phase3.md)
➡️ **다음 단계**: [Phase 5 - crontab 자동 실행 등록](./Phase5.md)
