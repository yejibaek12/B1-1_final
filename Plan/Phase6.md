# Phase 6. 수행 내역서 작성

> **목표**: 과제 전 단계에서 수집한 증거 자료를 정리하여 제출용 수행 내역서를 완성합니다.

---

## 수행 내역서 구성

수행 내역서는 아래 8가지 항목 각각에 대해 **실행 명령어 + 결과 캡처(스크린샷 또는 텍스트)**를 포함해야 합니다.

---

## 체크리스트 1. SSH 포트 변경 및 Root 원격 접속 차단 확인

### 수집 명령어

```bash
# sshd_config 설정값 확인
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config

# sshd가 20022 포트에서 LISTEN 중인지 확인
sudo ss -tulnp | grep sshd
```

### 기대 출력

```
Port 20022
PermitRootLogin no

tcp  LISTEN 0  128  0.0.0.0:20022  0.0.0.0:*  users:(("sshd",...))
```

---

## 체크리스트 2. 방화벽 활성화 및 허용 포트 확인

### 수집 명령어

```bash
sudo ufw status verbose
```

### 기대 출력

```
Status: active
...
To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW IN    Anywhere
15034/tcp                  ALLOW IN    Anywhere
```

---

## 체크리스트 3. 계정 및 그룹 생성 확인

### 수집 명령어

```bash
id agent-admin
id agent-dev
id agent-test

# 그룹 목록 확인
grep "agent" /etc/group
```

### 기대 출력

```
uid=...(agent-admin) ... groups=...,agent-common,agent-core
uid=...(agent-dev)   ... groups=...,agent-common,agent-core
uid=...(agent-test)  ... groups=...,agent-common
```

---

## 체크리스트 4. 디렉토리 구조 및 권한(ACL) 확인

### 수집 명령어

```bash
# 디렉토리 목록 및 기본 권한
ls -l /home/agent-admin/agent-app/
ls -ld /var/log/agent-app

# ACL 상세 확인
getfacl /home/agent-admin/agent-app/upload_files
getfacl /home/agent-admin/agent-app/api_keys
getfacl /var/log/agent-app
```

---

## 체크리스트 5. 앱 Boot Sequence 5단계 [OK] 및 "Agent READY" 출력

### 수집 방법

앱을 `agent-admin` 계정으로 실행하여 콘솔 출력 전체를 캡처합니다:

```bash
sudo su - agent-admin
cd $AGENT_HOME
./agent-app-linux-x86
```

### 기대 출력

```
Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
... Running as service user 'agent-admin' (uid=...)
[2/5] Verifying Environment Variables     [OK]
... All required Envs correct
[3/5] Checking Required Files             [OK]
... Verified key file with correct key string.
[4/5] Checking Port Availability          [OK]
... Port 15034 is available.
[5/5] Verifying Log Permission            [OK]
... Log directory is writable: /var/log/agent-app
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
```

> ⚠️ 5단계 중 하나라도 `[FAIL]`이 있으면 해당 Phase로 돌아가 수정 후 다시 캡처합니다.

---

## 체크리스트 6. `monitor.sh` 실행 결과 확인

### 수집 방법

앱이 실행 중인 상태에서 `agent-admin` 계정으로 `monitor.sh`를 실행합니다:

```bash
sudo su - agent-admin
/home/agent-admin/agent-app/bin/monitor.sh
```

콘솔 출력 전체를 캡처합니다. (Health Check, Resource, WARNING, Log appended 포함)

---

## 체크리스트 7. `/var/log/agent-app/monitor.log` 누적 로그 확인

### 수집 명령어

```bash
# 최근 로그 라인 확인
tail -10 /var/log/agent-app/monitor.log

# 전체 라인 수 확인
wc -l /var/log/agent-app/monitor.log
```

### 기대 출력

```
[2026-06-28 23:30:01] PID:48291 CPU:5.3% MEM:8.2% DISK_USED:23%
[2026-06-28 23:31:01] PID:48291 CPU:4.8% MEM:8.1% DISK_USED:23%
[2026-06-28 23:32:01] PID:48291 CPU:6.1% MEM:8.3% DISK_USED:23%
```

---

## 체크리스트 8. crontab 매분 실행 등록 및 자동 실행 확인

### 수집 명령어

```bash
# crontab 등록 내용 확인
sudo su - agent-admin -c "crontab -l"

# 시점 1: 현재 로그 라인 수
wc -l /var/log/agent-app/monitor.log

# (1~2분 대기)

# 시점 2: 증가된 로그 라인 수
wc -l /var/log/agent-app/monitor.log
```

두 시점의 라인 수를 비교하여 자동 실행 증거로 첨부합니다.

---

## 수행 내역서 작성 가이드

아래 템플릿을 참고하여 Markdown 또는 Word 문서로 작성합니다:

```markdown
# B1-1 수행 내역서

## 1. SSH 설정
- 변경 내용: Port 22 → 20022, PermitRootLogin no
- 확인 명령어: grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config
- 실행 결과:
  [캡처 이미지 또는 텍스트 붙여넣기]

## 2. 방화벽 설정
...

## 3. 계정 및 그룹
...

## 4. 디렉토리 권한
...

## 5. Boot Sequence
...

## 6. monitor.sh 실행 결과
...

## 7. monitor.log 누적 확인
...

## 8. crontab 자동 실행 확인
...
```

---

## 최종 제출 파일 목록

| 파일 | 설명 |
|------|------|
| 수행 내역서 (PDF 또는 Markdown) | 8개 체크리스트 증거 자료 포함 |
| `monitor.sh` | `$AGENT_HOME/bin/monitor.sh` 소스코드 |

---

## 전체 완료 체크리스트

- [ ] SSH 포트 20022 변경 + Root 로그인 차단 캡처 완료
- [ ] 방화벽 상태 캡처 완료
- [ ] 계정/그룹 생성 캡처 완료
- [ ] 디렉토리 권한 및 ACL 캡처 완료
- [ ] Boot Sequence 5단계 `[OK]` 캡처 완료
- [ ] `monitor.sh` 실행 결과 캡처 완료
- [ ] `monitor.log` 누적 로그 캡처 완료
- [ ] crontab 등록 및 자동 실행 증거 캡처 완료
- [ ] 수행 내역서 문서 완성
- [ ] `monitor.sh` 소스코드 별도 파일로 저장

---

⬅️ **이전 단계**: [Phase 5 - crontab 자동 실행 등록](./Phase5.md)
