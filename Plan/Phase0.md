# Phase 0. WSL (Windows Subsystem for Linux) 환경 설정 및 준비

> **목표**: 이미 설치된 WSL(우분투) 환경에서 과제에 필요한 `systemd` 시스템 제어 기능을 활성화하고, 필수 패키지를 설치하여 준비 상태로 만듭니다.

---

## 0-1. WSL의 Systemd(시스템 제어) 활성화하기

> ⚠️ **중요**: WSL은 기본적으로 `systemctl` 명령어(서비스 관리 도구)가 비활성화되어 있습니다. 과제에서 SSH 서버(`sshd`)와 크론(`cron`) 데몬을 제어하기 위해 반드시 활성화해주어야 합니다.

### Step 1. wsl.conf 파일 설정 변경
WSL 터미널(Antigravity IDE 내부의 WSL 터미널)을 열고 아래 명령어를 한 줄씩 복사해서 실행합니다:

```bash
# wsl.conf 파일에 systemd=true 옵션 추가하기
sudo sh -c 'echo -e "[boot]\nsystemd=true" > /etc/wsl.conf'
```
> 💡 `[sudo] password for ...`가 나타나면 본인의 WSL 우분투 계정 비밀번호를 입력합니다. (입력 시 화면에 비밀번호가 노출되지 않지만 정상 입력되고 있는 것입니다.)

설정이 올바르게 입력되었는지 확인합니다:
```bash
cat /etc/wsl.conf
```
**예상 출력:**
```text
[boot]
systemd=true
```

### Step 2. WSL 재부팅하기 (윈도우 PowerShell에서 실행)
설정을 적용하려면 WSL을 완전히 껐다 켜야 합니다.

1. **윈도우 자체 PowerShell**을 새로 실행하거나, IDE 하단 터미널을 잠시 Windows PowerShell(또는 Command Prompt) 세션으로 전환합니다.
2. 아래 종료 명령어를 실행합니다:
   ```powershell
   wsl --shutdown
   ```
3. 종료가 완료되면 IDE에서 다시 **WSL 터미널**을 열어줍니다. (자동으로 켜지면서 재부팅이 완료됩니다.)

### Step 3. Systemd 작동 검증
WSL 터미널에서 아래 명령어를 실행해 봅니다:
```bash
systemctl is-system-running
```
**예상 출력:**
```text
running
```
> 만약 `running`이 아닌 `offline`이나 에러가 나타난다면 Step 1, 2 과정을 정확히 다시 시도해 주세요.

---

## 0-2. 필수 도구 및 패키지 설치

WSL 터미널에서 아래 패키지들을 최신 상태로 업데이트하고 한 번에 설치합니다:

```bash
# 1. 패키지 저장소 목록 업데이트
sudo apt update

# 2. 과제 수행에 필수적인 도구들 설치
sudo apt install -y openssh-server ufw acl net-tools bc unzip
```

---

## 0-3. WSL 네트워크의 특징과 포트 테스트

> 💡 **WSL은 포트 포워딩 설정이 불필요합니다!**
> WSL 2는 기본적으로 윈도우(호스트 OS)와 네트워크를 자동으로 공유합니다. 
> 즉, 가상 머신(VirtualBox)처럼 따로 포트 포워딩을 지정할 필요 없이, WSL에서 특정 포트(예: 20022, 15034)를 LISTEN 상태로 만들면 윈도우 PC에서 `localhost` 주소로 바로 접근할 수 있습니다.

### Step 1. SSH 서비스 임시 시작
현재 기본 설정인 22번 포트로 SSH를 실행해 봅니다.
```bash
sudo systemctl start ssh
```

### Step 2. 윈도우 PowerShell에서 WSL로 SSH 접속 테스트
1. 윈도우 PowerShell 창을 엽니다.
2. 다음 명령어를 실행합니다 (여기서 `ubuntu` 자리는 본인의 WSL 로그인 계정명으로 변경해 주세요):
   ```powershell
   ssh byj@127.0.0.1 -p 20022
   ```
   > 💡 포트 옵션(`-p`)을 적지 않으면 기본 22번 포트로 접속을 시도합니다.
3. `Are you sure you want to continue connecting...` 문구가 뜨면 `yes`를 입력합니다.
4. WSL 계정 비밀번호를 입력하여 로그인이 정상적으로 수행되는지 확인합니다.
5. 확인이 끝났으면 `exit`를 입력해 접속을 종료합니다.

---

⬅️ [전체 계획서 보기](./plan.md)  
➡️ **다음 단계**: [Phase 1 - 기초 보안 설정 (SSH + 방화벽)](./Phase1.md)
