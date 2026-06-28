# Phase 3. 애플리케이션 실행 환경 구성

> **목표**: 환경 변수를 설정하고, API 키 파일을 생성한 뒤, Python 앱을 `agent-admin` 계정으로 실행하여 Boot Sequence 5단계를 검증합니다.

---

## 3-1. 환경 변수 설정

### Step 1. agent-admin 계정으로 전환

```bash
sudo su - agent-admin
```

### Step 2. ~/.bashrc에 환경 변수 추가

```bash
nano ~/.bashrc
```

파일 맨 아래에 다음을 추가합니다:

```bash
# Agent App 환경 변수
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys
export AGENT_LOG_DIR=/var/log/agent-app
```

저장 후 종료 (`Ctrl+O` → `Ctrl+X`)

### Step 3. 환경 변수 적용

```bash
source ~/.bashrc
```

### Step 4. 검증

```bash
echo $AGENT_HOME
echo $AGENT_PORT
echo $AGENT_UPLOAD_DIR
echo $AGENT_KEY_PATH
echo $AGENT_LOG_DIR
```

**예상 출력:**
```
/home/agent-admin/agent-app
15034
/home/agent-admin/agent-app/upload_files
/home/agent-admin/agent-app/api_keys/t_secret.key
/var/log/agent-app
```

---

## 3-2. API 키 파일 생성

`agent-admin` 계정으로 진행합니다 (이미 전환되어 있는 상태).

```bash
# API 키 파일 생성
echo "agent_api_key_test" > $AGENT_HOME/api_keys/t_secret.key

# 제공된 앱의 요구사항에 따라 secret.key 파일로도 복사
cp /home/agent-admin/agent-app/api_keys/t_secret.key /home/agent-admin/agent-app/api_keys/secret.key

# 권한 설정 (소유자만 읽기/쓰기, 그룹 읽기)
chmod 640 $AGENT_HOME/api_keys/t_secret.key
chmod 640 $AGENT_HOME/api_keys/secret.key
```

**검증:**
```bash
cat $AGENT_HOME/api_keys/t_secret.key
cat $AGENT_HOME/api_keys/secret.key
ls -l $AGENT_HOME/api_keys/
```

**예상 출력:**
```
agent_api_key_test
agent_api_key_test
-rw-r----- 1 agent-admin agent-core ... t_secret.key
-rw-r----- 1 agent-admin agent-core ... secret.key
```

---

## 3-3. 앱 파일 배포

### Step 1. agent-app.zip 압축 해제

> 💡 **WSL에서의 윈도우 파일 접근:**
> WSL은 윈도우의 `C:\` 드라이브를 `/mnt/c/` 경로에 자동으로 마운트합니다. 따라서 윈도우 폴더에 있는 zip 파일을 직접 가상 머신 내부로 압축 해제할 수 있습니다.

```bash
# 윈도우 바탕화면 폴더의 zip 파일을 앱 홈 디렉토리($AGENT_HOME)로 바로 압축 해제
unzip /mnt/c/Users/byjyj/Desktop/Codyssey/B1-1/agent-app.zip -d $AGENT_HOME
```

### Step 2. 아키텍처 확인 및 바이너리 선택

```bash
uname -m
```

| 출력값 | 사용할 바이너리 |
|--------|----------------|
| `x86_64` | `agent-app-linux-x86` |
| `aarch64` | `agent-app-linux-arm64` |

### Step 3. 실행 권한 부여

환경 변수 오류를 방지하기 위해, 먼저 앱 폴더로 이동한 후 상대 경로로 실행 권한을 부여합니다.

```bash
# 1. 앱 폴더로 이동
cd $AGENT_HOME

# 2. 실행 권한 부여 (x86 환경)
chmod +x ./agent-app-linux-x86
```

> 💡 **여기서 에러가 발생한다면? (트러블슈팅)**
> 
> **Q. `No such file or directory` 에러가 납니다.**
> 1. 현재 터미널 세션에 `$AGENT_HOME` 환경 변수가 잘 설정되었는지 `echo $AGENT_HOME` 명령어로 확인해 보세요. 빈칸이 나온다면 `source ~/.bashrc`를 입력한 후 다시 시도합니다.
> 2. `ls -l` 명령어를 입력하여 현재 폴더에 `agent-app-linux-x86` 파일이 진짜 들어있는지 확인합니다. 만약 zip 압축을 풀 때 하위 폴더가 더 생겼다면 `cd`로 그 폴더 안까지 들어가야 합니다.
> 
> **Q. `Permission denied` 에러가 납니다.**
> - 파일의 소유자가 현재 로그인한 계정(`agent-admin` 또는 `agent-dev`)이 아니어서 권한 수정이 안 되는 상태입니다. 명령어 앞에 `sudo`를 붙여 `sudo chmod +x ./agent-app-linux-x86`으로 권한을 준 뒤, 파일 소유권을 수정해야 합니다.

---

## 3-4. 앱 실행 및 Boot Sequence 검증

> ⚠️ **반드시 `agent-admin` 계정으로 실행해야 합니다. Root 권한 실행 절대 금지.**

### Step 1. 앱 실행

```bash
# agent-admin 계정으로 전환 (아직 안 되어 있는 경우)
sudo su - agent-admin

# 앱 실행
cd $AGENT_HOME
./agent-app-linux-x86
```

ARM 환경:
```bash
./agent-app-linux-arm64
```

### Step 2. Boot Sequence 확인

5단계가 모두 `[OK]`로 출력되고 `Agent READY`가 표시되어야 합니다:

```
Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
... Running as service user 'agent-admin' (uid=1001)
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

> ❌ 특정 단계에서 `[FAIL]`이 뜰 경우:
> - `[1/5]` 실패: Root 계정으로 실행하고 있지 않은지 확인. `agent-admin`으로 재실행
> - `[2/5]` 실패: 환경 변수 설정 확인 (`echo $AGENT_HOME` 등)
> - `[3/5]` 실패: `t_secret.key` 파일 존재 및 내용 확인 (`cat $AGENT_KEY_PATH`)
> - `[4/5]` 실패: 포트 15034가 이미 사용 중 → `ss -tulnp | grep 15034` 확인
> - `[5/5]` 실패: `/var/log/agent-app` 권한 확인 → Phase 2 ACL 재설정

### Step 3. 포트 LISTEN 상태 확인

앱이 실행 중인 상태에서 **새 터미널**을 열어 확인합니다:

```bash
ss -tulnp | grep 15034
```

**예상 출력:**
```
tcp  LISTEN  0  128  0.0.0.0:15034  0.0.0.0:*  users:((...))
```

### Step 4. 앱 종료

테스트 완료 후 `Ctrl+C`로 앱을 종료합니다.

> **중요**: Phase 4에서 monitor.sh를 테스트할 때는 앱이 실행 중이어야 합니다. crontab 등록 전에 앱을 백그라운드로 실행하거나 Phase 5 직전에 재실행하세요.

```bash
# 백그라운드 실행 방법 (crontab 등록 전까지 유지)
nohup ./agent-app-linux-x86 > /dev/null 2>&1 &
```

---

## 완료 체크리스트

- [ ] 환경 변수 5개 모두 `~/.bashrc`에 등록 완료
- [ ] `source ~/.bashrc` 적용 완료
- [ ] `secret.key` 파일 생성 및 내용 확인 완료
- [ ] 바이너리 실행 권한 부여 완료
- [ ] Boot Sequence 5단계 모두 `[OK]` 확인
- [ ] `Agent READY` 문구 출력 확인
- [ ] `0.0.0.0:15034` LISTEN 상태 확인

---

## 증거 자료 수집 (수행 내역서용)

```bash
# 환경 변수 확인
printenv | grep AGENT

# API 키 파일 확인
ls -l $AGENT_HOME/api_keys/
cat $AGENT_HOME/api_keys/t_secret.key

# Boot Sequence 출력 (캡처)
./agent-app-linux-x86

# 포트 상태 확인 (앱 실행 중 다른 터미널에서)
ss -tulnp | grep 15034
```

---

⬅️ **이전 단계**: [Phase 2 - 계정/그룹/권한 구성](./Phase2.md)
➡️ **다음 단계**: [Phase 4 - monitor.sh 구현](./Phase4.md)
