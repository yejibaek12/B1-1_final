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
