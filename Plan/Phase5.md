# Phase 5. crontab 등록 및 자동 실행 검증

> **목표**: `agent-admin` 계정의 crontab에 `monitor.sh`를 매분 실행하도록 등록하고, 로그가 자동으로 누적되는지 검증합니다.

---

## 사전 확인

crontab 등록 전에 아래 상태를 확인합니다:

```bash
# 1. 앱이 백그라운드로 실행 중인지 확인
pgrep -f agent-app-linux-x86 && echo "앱 실행 중" || echo "앱 미실행"

# 2. monitor.sh가 수동으로 실행 가능한지 재확인
sudo su - agent-admin -c "/home/agent-admin/agent-app/bin/monitor.sh"
```

> 앱이 실행 중이 아니라면 먼저 백그라운드로 실행합니다:
> ```bash
> sudo su - agent-admin -c "nohup /home/agent-admin/agent-app/agent-app-linux-x86 > /dev/null 2>&1 &"
> ```

---

## 5-1. crontab 등록

`agent-admin` 계정으로 전환 후 crontab을 엽니다:

```bash
sudo su - agent-admin
crontab -e
```

> 처음 실행 시 에디터를 선택하는 프롬프트가 나올 수 있습니다. `1` (nano) 을 선택합니다.

파일 맨 아래에 다음 줄을 추가합니다:

```cron
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

> `* * * * *` = 매분 실행
> `>> /var/log/agent-app/cron.log 2>&1` = crontab 실행 오류도 별도 로그로 기록 (디버깅용)

저장 후 종료 (`Ctrl+O` → `Ctrl+X`)

---

## 5-2. crontab 등록 확인

```bash
crontab -l
```

**예상 출력:**
```
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

---

## 5-3. cron 서비스 상태 확인

```bash
exit  # agent-admin 세션 종료
sudo systemctl status cron
```

**예상 출력:**
```
● cron.service - Regular background program processing daemon
     Loaded: loaded (/lib/systemd/system/cron.service; enabled; ...)
     Active: active (running) ...
```

> cron이 inactive 상태라면:
> ```bash
> sudo systemctl start cron
> sudo systemctl enable cron
> ```

---

## 5-4. 자동 실행 검증

### 1~2분 대기 후 로그 확인

```bash
# 실시간 로그 스트리밍 (Ctrl+C로 종료)
tail -f /var/log/agent-app/monitor.log
```

**예상 출력 (매분 1줄씩 추가됨):**
```
[2026-06-28 23:30:01] PID:48291 CPU:5.3% MEM:8.2% DISK_USED:23%
[2026-06-28 23:31:01] PID:48291 CPU:4.8% MEM:8.1% DISK_USED:23%
[2026-06-28 23:32:01] PID:48291 CPU:6.1% MEM:8.3% DISK_USED:23%
```

### 로그 라인 수 확인

```bash
wc -l /var/log/agent-app/monitor.log
```

1~2분 간격으로 이 명령을 반복 실행하여 라인 수가 증가하는지 확인합니다.

### 로그 파일 크기 확인

```bash
ls -lh /var/log/agent-app/monitor.log
```

---

## 5-5. cron 실행 로그 확인 (문제 발생 시)

```bash
# cron 실행 기록 확인
grep CRON /var/log/syslog | tail -20

# cron 오류 로그 확인 (별도 기록한 경우)
cat /var/log/agent-app/cron.log
```

---

## 트러블슈팅

| 증상 | 원인 | 해결 방법 |
|------|------|----------|
| 로그가 쌓이지 않음 | cron 서비스 미실행 | `sudo systemctl start cron` |
| 로그가 쌓이지 않음 | 환경 변수 미설정 (cron은 `.bashrc` 미참조) | crontab에 환경 변수 직접 선언 |
| `exit 1` 오류 | 앱이 실행 중이지 않음 | 앱 백그라운드 실행 후 재시도 |
| 권한 오류 | `agent-admin`이 로그 디렉토리에 쓰기 불가 | Phase 2 ACL 재설정 확인 |

### crontab에 환경 변수 직접 선언하는 방법 (필요 시)

cron 환경은 `.bashrc`를 읽지 않으므로, 환경 변수가 필요한 경우 crontab 상단에 직접 선언합니다:

```cron
AGENT_HOME=/home/agent-admin/agent-app
AGENT_PORT=15034
AGENT_UPLOAD_DIR=/home/agent-admin/agent-app/upload_files
AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys/t_secret.key
AGENT_LOG_DIR=/var/log/agent-app

* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

---

## 완료 체크리스트

- [ ] `crontab -l` 에서 등록 내용 확인 완료
- [ ] cron 서비스 `active (running)` 상태 확인
- [ ] 1분 후 `/var/log/agent-app/monitor.log` 라인 추가 확인
- [ ] 2분 후 로그 라인 수 증가 확인

---

## 증거 자료 수집 (수행 내역서용)

```bash
# crontab 등록 내용 확인
sudo su - agent-admin -c "crontab -l"

# 1분 후 로그 파일 라인 수 확인 (초기)
wc -l /var/log/agent-app/monitor.log

# 2분 후 로그 파일 라인 수 확인 (증가 확인)
wc -l /var/log/agent-app/monitor.log

# 최근 로그 내용 확인
tail -5 /var/log/agent-app/monitor.log
```

위 결과를 캡처하여 수행 내역서에 첨부합니다.

---

⬅️ **이전 단계**: [Phase 4 - monitor.sh 구현](./Phase4.md)
➡️ **다음 단계**: [Phase 6 - 수행 내역서 작성](./Phase6.md)
