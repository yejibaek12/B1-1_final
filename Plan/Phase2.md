# Phase 2. 계정 / 그룹 / 디렉토리 권한 구성

> **목표**: 역할 기반 계정과 그룹을 생성하고, 디렉토리를 구성한 뒤 ACL을 통해 최소 권한 정책을 적용합니다.

---

## 2-1. 그룹 생성

```bash
# agent-common: 모든 사용자 포함 (admin, dev, test)
sudo groupadd agent-common

# agent-core: 핵심 사용자만 포함 (admin, dev)
sudo groupadd agent-core
```

**검증:**
```bash
cat /etc/group | grep agent
```

---

## 2-2. 계정 생성

```bash
sudo useradd -m -s /bin/bash agent-admin
sudo useradd -m -s /bin/bash agent-dev
sudo useradd -m -s /bin/bash agent-test
```

> `-m`: 홈 디렉토리 생성 / `-s /bin/bash`: bash 셸 지정

**검증:**
```bash
cat /etc/passwd | grep agent
```

---

## 2-3. 계정을 그룹에 배정

### agent-common 그룹 (전체 계정)

```bash
sudo usermod -aG agent-common agent-admin
sudo usermod -aG agent-common agent-dev
sudo usermod -aG agent-common agent-test
```

> 💡 **`-aG` 옵션 설명:**
> - `-G` (Groups): 사용자를 특정 그룹에 배정합니다.
> - `-a` (Append): 사용자가 기존에 소속되어 있던 다른 그룹을 **유지한 채** 새로운 그룹을 추가(덧붙임)합니다.
> - **주의**: 만약 `-a`를 빼고 `sudo usermod -G ...`만 쓰면, 해당 사용자가 기존에 속해 있던 그룹(예: `sudo` 권한 그룹 등)에서 강제로 탈퇴되므로 **반드시 `-aG`를 함께 써야 합니다.**

### agent-core 그룹 (admin, dev만)

```bash
sudo usermod -aG agent-core agent-admin
sudo usermod -aG agent-core agent-dev
```

### 검증

```bash
id agent-admin
id agent-dev
id agent-test
```

**예상 출력 (agent-admin):**
```
uid=1001(agent-admin) gid=1001(agent-admin) groups=1001(agent-admin),1002(agent-common),1003(agent-core)
```

**예상 출력 (agent-test):**
```
uid=1003(agent-test) gid=1003(agent-test) groups=1003(agent-test),1002(agent-common)
```

> 💡 **출력 결과 항목 설명:**
> - **`uid` (User ID)**: 현재 계정의 고유 사용자 번호와 계정명입니다.
> - **`gid` (Group ID)**: 이 사용자의 기본(주) 그룹 번호와 그룹명입니다. (보통 계정명과 동일하게 자동 생성됩니다.)
> - **`groups`**: 이 사용자가 속해 있는 **모든 그룹 목록**입니다. 
>   - `agent-admin`은 `agent-common`과 `agent-core`에 둘 다 속해 있어야 하고,
>   - `agent-test`는 `agent-common`에만 속해 있어야 과제 조건에 맞습니다.
> 
> ※ **참고**: `1001`, `1002` 등의 숫자는 사용자의 리눅스 시스템 상태에 따라 다르게 나타날 수 있으므로, 괄호 안의 이름(`agent-common`, `agent-core`)이 제대로 적혀 있는지만 확인하시면 됩니다.

---

## 2-4. 디렉토리 구조 생성

```bash
# AGENT_HOME 기준 경로
sudo mkdir -p /home/agent-admin/agent-app/upload_files
sudo mkdir -p /home/agent-admin/agent-app/api_keys
sudo mkdir -p /home/agent-admin/agent-app/bin
sudo mkdir -p /var/log/agent-app
```

**검증:**
```bash
sudo ls -l /home/agent-admin/agent-app/
sudo ls -ld /var/log/agent-app
```

> 💡 **디렉토리 구조 및 소유권 확인 (`ls -l`)**
> 
> 위 명령어를 실행하면 다음과 같은 결과가 출력됩니다.
> - `/home/agent-admin/agent-app/`: `agent-admin` 사용자가 소유자(owner)이며, `agent-admin` 그룹에 속해 있음을 보여줍니다.
> - `/var/log/agent-app`: 시스템 로그 디렉토리로, 소유자가 `/var/log`와 동일하게 설정됩니다.
> 
> 이 단계에서는 단순히 디렉토리가 존재하는지와 기본적인 소유권만 확인합니다. ( ACL 권한 설정은 다음 단계에서 다룹니다.)

---

## 2-5. ACL 권한 설정

> `acl` 패키지가 없으면 먼저 설치합니다:
> ```bash
> sudo apt-get install -y acl
> ```

### $AGENT_HOME — 소유권 변경 (매우 중요)

디렉토리 구조를 생성할 때 `sudo`를 사용했기 때문에 앱 루트 폴더가 `root` 소유로 되어 있습니다. 이를 `agent-admin` 소유로 바꾸어 주어야 나중에 파일을 배포할 수 있습니다.

```bash
sudo chown agent-admin:agent-common /home/agent-admin/agent-app
sudo chmod 775 /home/agent-admin/agent-app
```

### upload_files — agent-common 그룹 R/W

```bash
# 소유권 설정
sudo chown agent-admin:agent-common /home/agent-admin/agent-app/upload_files

# 기본 권한 설정 (소유자 rwx, 그룹 rwx, 기타 ---)
sudo chmod 770 /home/agent-admin/agent-app/upload_files

# ACL: agent-common 그룹에 rwx 명시
sudo setfacl -m g:agent-common:rwx /home/agent-admin/agent-app/upload_files
```

> 💡 **명령어 및 옵션 설명:**
> - **`chown [소유자]:[그룹] [경로]`** (Change Owner): 디렉토리의 소유자와 그룹 소유권을 동시에 변경합니다.
> - **`chmod [권한값] [경로]`** (Change Mode): 전통적인 리눅스 파일 권한을 설정합니다.
>   - `770`은 **소유자(7: rwx), 그룹(7: rwx), 나머지 외부인(0: ---)**으로 권한을 지정하여 외부 계정이 절대 들어올 수 없게 차단합니다.
> - **`setfacl -m g:[그룹명]:[권한] [경로]`** (Set File ACL): 
>   - **`setfacl`**: 기본 권한 체계보다 더 정교하고 유연하게 개별 사용자나 특정 그룹에 권한을 추가할 수 있는 ACL(Access Control List) 설정 도구입니다.
>   - **`-m` (Modify)**: 기존 파일/폴더의 ACL 설정을 수정하거나 추가합니다.
>   - **`g:agent-common:rwx`**: **그룹(g)** 중 `agent-common` 그룹에 읽기(r), 쓰기(w), 실행(x) 권한을 명시적으로 부여합니다.

### api_keys — agent-core 그룹만 R/W

```bash
sudo chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys
sudo chmod 770 /home/agent-admin/agent-app/api_keys
sudo setfacl -m g:agent-core:rwx /home/agent-admin/agent-app/api_keys

# 기타 그룹 접근 차단
sudo setfacl -m o::--- /home/agent-admin/agent-app/api_keys
```

> 💡 **`o::---` 옵션 설명:**
> - **`o` (Others)**: 파일/폴더의 소유자도 아니고, 권한을 부여받은 그룹(여기서는 `agent-core`) 소속도 아닌 **나머지 모든 제3의 외부인(기타 사용자)**을 의미합니다.
> - **`::---`**: 아무런 권한(읽기, 쓰기, 실행)도 주지 않겠다는 뜻(`---`)입니다.
> - **목적**: `agent-test` 계정은 공통 그룹인 `agent-common`에는 들어있지만 핵심 그룹인 `agent-core`에는 속해있지 않습니다. 따라서 이 명령을 명시적으로 적어주어 `agent-test`와 같이 권한이 없는 계정이 API 키 디렉토리에 몰래 접근하는 것을 원천 차단합니다.

### /var/log/agent-app — agent-core 그룹만 R/W

```bash
sudo chown agent-admin:agent-core /var/log/agent-app
sudo chmod 770 /var/log/agent-app
sudo setfacl -m g:agent-core:rwx /var/log/agent-app
sudo setfacl -m o::--- /var/log/agent-app
```

### 검증

```bash
# 소유권 및 기본 권한 확인
sudo ls -l /home/agent-admin/agent-app/

# ACL 상세 확인
sudo getfacl /home/agent-admin/agent-app/upload_files
sudo getfacl /home/agent-admin/agent-app/api_keys
sudo getfacl /var/log/agent-app
```

**upload_files 예상 출력:**
```
# file: upload_files
# owner: agent-admin
# group: agent-common
user::rwx
group::rwx
group:agent-common:rwx
mask::rwx
other::---
```

> 💡 **`getfacl` 출력 결과 상세 설명:**
> - **`# file`**: ACL을 확인하고 있는 파일 또는 폴더명입니다.
> - **`# owner`**: 해당 폴더의 소유자(여기서는 `agent-admin`)입니다.
> - **`# group`**: 해당 폴더의 대표 소유 그룹(여기서는 `agent-common`)입니다.
> - **`user::rwx`**: 소유자(`owner`)의 권한입니다. 읽기/쓰기/실행(`rwx`)이 모두 허용됩니다.
> - **`group::rwx`**: 기본 소유 그룹의 권한입니다. 마찬가지로 `rwx` 권한을 갖습니다.
> - **`group:agent-common:rwx`**: ACL을 통해 `agent-common` 그룹에 명시적으로 부여된 권한입니다.
> - **`mask::rwx`**: ACL 설정을 통해 부여할 수 있는 **최대 한계 권한(마스크)**입니다. 개별 권한이 아무리 높아도 이 마스크 권한을 넘을 수 없습니다. (여기서는 `rwx`이므로 모든 권한이 제한 없이 잘 적용됩니다.)
> - **`other::---`**: 소유자도 아니고 지정된 그룹 소속도 아닌 사람의 권한입니다. `---`이므로 **아무런 접근도 할 수 없음**을 뜻합니다. (보안상 매우 중요)

---

## 완료 체크리스트

- [ ] `agent-common`, `agent-core` 그룹 생성 완료
- [ ] `agent-admin`, `agent-dev`, `agent-test` 계정 생성 완료
- [ ] `agent-common`에 세 계정 모두 포함 확인
- [ ] `agent-core`에 admin, dev만 포함 확인
- [ ] `upload_files` ACL: agent-common R/W 확인
- [ ] `api_keys` ACL: agent-core만 R/W 확인
- [ ] `/var/log/agent-app` ACL: agent-core만 R/W 확인

---

## 증거 자료 수집 (수행 내역서용)

```bash
# 계정 그룹 확인
id agent-admin
id agent-dev
id agent-test

# 디렉토리 권한 확인
sudo ls -l /home/agent-admin/agent-app/
sudo ls -ld /var/log/agent-app

# ACL 확인
sudo getfacl /home/agent-admin/agent-app/upload_files
sudo getfacl /home/agent-admin/agent-app/api_keys
sudo getfacl /var/log/agent-app
```

---

⬅️ **이전 단계**: [Phase 1 - SSH/방화벽 설정](./Phase1.md)
➡️ **다음 단계**: [Phase 3 - 앱 실행 환경 구성](./Phase3.md)
