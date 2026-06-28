# Phase 1. 기초 보안 설정 (SSH + 방화벽)

> **목표**: SSH 포트를 20022로 변경하고, Root 원격 로그인을 차단합니다. UFW 방화벽을 활성화하여 허용 포트를 최소화합니다.

---

## 사전 확인

```bash
# 현재 SSH 포트 확인
sudo ss -tulnp | grep sshd

# UFW 설치 여부 확인
sudo ufw version
```

---

## 1-1. SSH 설정 변경

### Step 1. sshd_config 파일 열기

```bash
sudo nano /etc/ssh/sshd_config
```

### Step 2. 포트 변경

파일에서 아래 줄을 찾아 수정합니다:

```
# 기존 (주석 처리되어 있을 수 있음)
#Port 22

# 변경 후
Port 20022
```

### Step 3. Root 로그인 차단

같은 파일에서 아래 줄을 찾아 수정합니다:

```
# 기존
#PermitRootLogin yes

# 변경 후
PermitRootLogin no
```

### Step 4. 파일 저장 및 닫기

- `Ctrl + O` → 저장
- `Ctrl + X` → 종료

### Step 5. sshd 재시작

```bash
sudo systemctl restart ssh
```

### Step 6. 검증

```bash
# sshd가 20022 포트에서 LISTEN 중인지 확인
sudo ss -tulnp | grep 20022
```

**예상 출력:**
```
tcp   LISTEN  0  128  0.0.0.0:20022  0.0.0.0:*  users:(("sshd",pid=...,fd=...))
```

> ⚠️ **주의**: SSH 포트 변경 후에는 기존 SSH 세션을 종료하지 마세요. 방화벽 설정을 완료하기 전까지 현재 접속을 유지해야 합니다.

---

## 1-2. 방화벽(UFW) 설정

### Step 1. 인바운드 기본 정책 설정

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### Step 2. 허용 포트 등록

```bash
# SSH 포트 허용
sudo ufw allow 20022/tcp

# 앱 포트 허용
sudo ufw allow 15034/tcp
```

### Step 3. UFW 활성화

```bash
sudo ufw enable
```

프롬프트가 나오면 `y` 입력 후 Enter

### Step 4. 검증

```bash
sudo ufw status
```

**예상 출력:**
```
Status: active

To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW       Anywhere
15034/tcp                  ALLOW       Anywhere
20022/tcp (v6)             ALLOW       Anywhere (v6)
15034/tcp (v6)             ALLOW       Anywhere (v6)
```

---

## 완료 체크리스트

- [ ] `Port 20022` 설정 완료
- [ ] `PermitRootLogin no` 설정 완료
- [ ] `ssh` 재시작 완료
- [ ] `ss -tulnp | grep 20022` 출력 확인
- [ ] UFW 활성화 완료
- [ ] TCP 20022, 15034 포트만 허용 확인

---

## 증거 자료 수집 (수행 내역서용)

```bash
# 1. sshd_config 설정 확인
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config

# 2. 포트 LISTEN 상태 확인
sudo ss -tulnp | grep 20022

# 3. 방화벽 상태 확인
sudo ufw status verbose
```

위 명령어 결과를 캡처하여 수행 내역서에 첨부합니다.

---

⬅️ **이전 단계**: [Phase 0 - VM 환경 구축 및 준비](./Phase0.md)
➡️ **다음 단계**: [Phase 2 - 계정/그룹/권한 구성](./Phase2.md)
