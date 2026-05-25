# OCI VM 생성 전체 절차

이 문서는 지금까지 수행한 OCI VM 생성 작업을 기준으로, 다음 VM 생성 시 반복 사용할 수 있는 절차를 정리한 것이다.

## 1. 기본 환경 점검

OCI CLI가 로컬에 설치되어 있는지 확인한다.

```bash
which oci
oci --version
```

OCI CLI 설정 파일과 API key 파일이 있는지 확인한다.

```bash
ls -la ~/.oci
ls -l ~/.oci/config ~/.oci/api-key.pem
```

tenancy OCID와 기본 리전을 확인한다.

```bash
awk -F= '/^tenancy=/{print $2; exit}' ~/.oci/config
awk -F= '/^region=/{print $2; exit}' ~/.oci/config
```

기본 SSH key가 있는지 확인한다.

```bash
ls -la ~/.ssh
```

`~/.ssh/id_ed25519` 또는 `~/.ssh/id_rsa` 같은 기본 key가 있으면 사용하고, 없으면 새로 생성한다.

```bash
if [ -f ~/.ssh/id_ed25519.pub ]; then
  SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_ed25519"
  SSH_PUBLIC_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
elif [ -f ~/.ssh/id_rsa.pub ]; then
  SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_rsa"
  SSH_PUBLIC_KEY_FILE="$HOME/.ssh/id_rsa.pub"
else
  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -C '<vm_name>'
  SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_ed25519"
  SSH_PUBLIC_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
fi
```

## 2. 기본 필수 정보 확보

생성 전에 다음 입력값과 기본값을 확정한다.

| 항목 | 필수 여부 | 기본값 또는 결정 규칙 |
|---|---:|---|
| VM 이름 | 필수 | 입력값 사용 |
| 리전 | 선택 | 입력하지 않으면 OCI CLI config의 기본 `region` 사용 |
| 이미지 | 선택 | 입력하지 않으면 Oracle Linux 9 최신 이미지 사용 |
| Shape type | 선택 | 입력하지 않으면 `e5` 사용 |
| CPU | 선택 | 입력하지 않으면 `2 OCPU` 사용 |
| Memory | 선택 | 입력하지 않으면 CPU당 `15GB` 사용 |
| 컴파트먼트 이름 | 필수 | 입력값으로 컴파트먼트 OCID 조회 |
| VCN | 조건부 | 입력하지 않고 해당 컴파트먼트에 VCN이 1개이면 그 VCN 사용, 없거나 2개 이상이면 입력 필수 |
| Subnet | 선택 | 입력하지 않으면 선택한 VCN의 public subnet 사용 |
| Boot volume | 선택 | 입력하지 않으면 `100GB` 사용 |

### VM 이름

VM 이름은 필수 입력값이다.

이 이름은 다음 항목에 사용한다.

- OCI instance display name
- SSH config alias

hostname label은 OCI DNS 규칙에 맞게 VM 이름에서 파생한다.

- 소문자 영문, 숫자, 하이픈만 사용
- 시작과 끝은 영문 또는 숫자 사용
- 점, 밑줄, 공백은 사용하지 않음

예시:

```text
taewan-ol9-dev-20260525
```

## 3. 리전 결정

리전을 입력하지 않으면 OCI CLI config의 기본 리전을 사용한다.

```bash
awk -F= '/^region=/{print $2}' ~/.oci/config
```

리전을 명시하는 경우 예시는 다음과 같다.

```text
us-chicago-1
```

## 4. 이미지 결정

이미지를 입력하지 않으면 Oracle Linux 9 최신 이미지를 사용한다.

최신 Oracle Linux 9 이미지는 컴파트먼트 OCID와 shape를 확인한 뒤 다음 명령으로 조회한다.

```bash
oci compute image list \
  --all \
  --compartment-id '<compartment_ocid>' \
  --operating-system 'Oracle Linux' \
  --operating-system-version '9' \
  --shape '<shape>' \
  --region '<region>' \
  --sort-by TIMECREATED \
  --sort-order DESC
```

앞선 작업에서는 다음 이미지를 사용했다.

```text
Oracle-Linux-9.7-2026.04.30-3
```

## 5. Shape 결정

Shape type은 `e5`, `e6` 중 선택한다.

기본값은 `e5`이다.

| 입력값 | OCI shape |
|---|---|
| `e5` | `VM.Standard.E5.Flex` |
| `e6` | `VM.Standard.E6.Flex` |

CPU를 입력하지 않으면 `2 OCPU`를 사용한다.

Memory를 입력하지 않으면 CPU당 `15GB`를 사용한다.

예시:

```text
2 OCPU * 15GB = 30GB memory
```

Shape 사용 가능 여부와 옵션은 다음 명령으로 확인한다.

```bash
oci compute shape list \
  --all \
  --compartment-id '<compartment_ocid>' \
  --availability-domain '<availability_domain>' \
  --region '<region>'
```

생성 시 사용할 shape config는 입력값으로 계산한다.

```text
ocpus = 입력값이 없으면 2
memoryInGBs = 입력값이 없으면 ocpus * 15
```

## 6. 컴파트먼트 결정

컴파트먼트 이름은 필수 입력값이다.

컴파트먼트 이름으로 OCID를 조회한다.

```bash
oci iam compartment list \
  --all \
  --compartment-id '<tenancy_ocid>' \
  --compartment-id-in-subtree true \
  --access-level ACCESSIBLE \
  --name '<compartment_name>' \
  --lifecycle-state ACTIVE \
  --region '<region>'
```

주의할 점:

- 컴파트먼트 이름은 대소문자를 정확히 확인한다.
- 같은 이름이 대소문자만 다르게 존재할 수 있다.

앞선 작업에서는 `TAEWAN.KIM` 컴파트먼트를 사용했다.

## 7. VCN 결정

VCN 이름을 입력하지 않은 경우 다음 규칙을 적용한다.

- 해당 컴파트먼트에 VCN이 1개이면 그 VCN을 사용한다.
- VCN이 없으면 VCN 입력이 필요하다.
- VCN이 2개 이상이면 VCN 입력이 필요하다.

VCN 목록 조회:

```bash
oci network vcn list \
  --all \
  --compartment-id '<compartment_ocid>' \
  --region '<region>'
```

앞선 작업에서는 다음 VCN을 사용했다.

```text
aitwvcn
```

## 8. Subnet 결정

Subnet을 지정하지 않으면 선택한 VCN의 public subnet을 기본으로 사용한다.

Public subnet 판단 기준:

```text
prohibit-public-ip-on-vnic = false
```

Subnet 목록 조회:

```bash
oci network subnet list \
  --all \
  --compartment-id '<compartment_ocid>' \
  --vcn-id '<vcn_ocid>' \
  --region '<region>'
```

앞선 작업에서는 다음 subnet을 사용했다.

```text
public subnet-aitwvcn
```

## 9. Boot Volume 결정

Boot volume 크기를 입력하지 않으면 기본값 `100GB`를 사용한다.

앞선 작업에서는 boot volume PV in-transit encryption도 활성화했다.

```text
boot-volume-size-in-gbs = 100
is-pv-encryption-in-transit-enabled = true
```

## 10. Availability Domain 확인

가용성 도메인을 조회한다.

```bash
oci iam availability-domain list \
  --compartment-id '<tenancy_ocid>' \
  --region '<region>'
```

앞선 작업에서는 다음 AD를 사용했다.

```text
fttO:US-CHICAGO-1-AD-1
```

## 11. VM 생성

필요 정보가 모두 확보되면 VM을 생성한다.

먼저 입력값과 기본값으로 사용할 변수를 정리한다.

```bash
VM_NAME='<vm_name>'
HOSTNAME_LABEL='<hostname_label>'
REGION='<region>'
COMPARTMENT_OCID='<compartment_ocid>'
AVAILABILITY_DOMAIN='<availability_domain>'
IMAGE_OCID='<image_ocid>'
SHAPE='<shape>'
PUBLIC_SUBNET_OCID='<public_subnet_ocid>'
SSH_PUBLIC_KEY_FILE='<ssh_public_key_file>'
OCPUS='2'
MEMORY_IN_GBS='30'
BOOT_VOLUME_SIZE_IN_GBS='100'
```

입력값이 없어서 기본값을 적용하는 경우:

```bash
OCPUS="${OCPUS:-2}"
MEMORY_IN_GBS="${MEMORY_IN_GBS:-$((OCPUS * 15))}"
BOOT_VOLUME_SIZE_IN_GBS="${BOOT_VOLUME_SIZE_IN_GBS:-100}"
```

VM을 생성한다.

```bash
oci compute instance launch \
  --compartment-id "${COMPARTMENT_OCID}" \
  --availability-domain "${AVAILABILITY_DOMAIN}" \
  --region "${REGION}" \
  --display-name "${VM_NAME}" \
  --hostname-label "${HOSTNAME_LABEL}" \
  --image-id "${IMAGE_OCID}" \
  --shape "${SHAPE}" \
  --shape-config "{\"ocpus\":${OCPUS},\"memoryInGBs\":${MEMORY_IN_GBS}}" \
  --boot-volume-size-in-gbs "${BOOT_VOLUME_SIZE_IN_GBS}" \
  --is-pv-encryption-in-transit-enabled true \
  --subnet-id "${PUBLIC_SUBNET_OCID}" \
  --assign-public-ip true \
  --ssh-authorized-keys-file "${SSH_PUBLIC_KEY_FILE}" \
  --wait-for-state RUNNING \
  --max-wait-seconds 1200 \
  --wait-interval-seconds 15
```

앞선 작업의 실제 생성값:

| 항목 | 값 |
|---|---|
| Region | `us-chicago-1` |
| Compartment | `TAEWAN.KIM` |
| VCN | `aitwvcn` |
| Subnet | `public subnet-aitwvcn` |
| Image | `Oracle-Linux-9.7-2026.04.30-3` |
| Shape | `VM.Standard.E5.Flex` |
| OCPU | `2` |
| Memory | `30GB` |
| Boot volume | `100GB` |
| Instance name | `taewan-ol9-dev-20260525` |

## 12. Public IP 확인

생성된 instance의 VNIC attachment를 조회한다.

```bash
oci compute vnic-attachment list \
  --all \
  --compartment-id '<compartment_ocid>' \
  --instance-id '<instance_ocid>' \
  --region '<region>'
```

VNIC OCID로 public IP를 확인한다.

```bash
oci network vnic get \
  --vnic-id '<vnic_ocid>' \
  --region '<region>'
```

앞선 작업에서 생성된 IP:

```text
Public IP: <public_ip>
Private IP: <private_ip>
```

## 13. SSH 접속 확인

SSH 접속을 확인한다.

```bash
ssh -i "${SSH_PRIVATE_KEY_FILE}" opc@<public_ip>
```

예시:

```bash
ssh -i ~/.ssh/id_ed25519 opc@<public_ip>
```

## 14. VM 초기 설치

VM에 SSH로 접속한 뒤 cloud-init 완료를 기다린다.

```bash
sudo cloud-init status --wait
```

Node.js 24 모듈을 활성화한다.

```bash
sudo dnf -y module reset nodejs
sudo dnf -y module enable nodejs:24
```

기본 패키지를 설치한다.

```bash
sudo dnf install -y \
  git \
  python3.12 \
  python3.12-pip \
  nodejs \
  npm \
  curl \
  ca-certificates \
  tar \
  gzip \
  unzip
```

OCI CLI를 설치한다.

```bash
python3.12 -m pip install --user --upgrade pip
python3.12 -m pip install --user --upgrade oci-cli
```

uv를 설치한다.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Claude Code와 Codex를 설치한다.

```bash
sudo npm install -g @anthropic-ai/claude-code @openai/codex
```

PATH를 설정한다.

```bash
grep -q 'HOME/.local/bin' "$HOME/.bashrc" || \
  printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"

export PATH="$HOME/.local/bin:$PATH"
```

## 15. OCI Config와 API Key 전송

로컬의 OCI config와 API key를 VM으로 전송한다.

주의: `api-key.pem`은 OCI API 인증에 쓰는 private key이다. VM 안에서 OCI CLI를 직접 실행해야 하는 경우에만 전송하고, 전송 후 권한을 `600`으로 제한한다.

```bash
ssh -i "${SSH_PRIVATE_KEY_FILE}" opc@<public_ip> \
  'mkdir -p /home/opc/.oci && chmod 700 /home/opc/.oci'

scp -i "${SSH_PRIVATE_KEY_FILE}" \
  ~/.oci/config \
  ~/.oci/api-key.pem \
  opc@<public_ip>:/home/opc/.oci/
```

VM 내부에서 파일 권한을 조정한다.

```bash
chmod 600 /home/opc/.oci/config /home/opc/.oci/api-key.pem
```

OCI config의 `key_file` 경로를 VM 내부 경로로 수정한다.

```bash
sed -i.bak -E \
  's#^key_file=.*#key_file=/home/opc/.oci/api-key.pem#' \
  /home/opc/.oci/config
```

## 16. OCI CLI 접속 테스트

VM 내부에서 OCI CLI가 정상 인증되는지 확인한다.

```bash
export PATH="$HOME/.local/bin:$PATH"

oci iam compartment get \
  --compartment-id '<compartment_ocid>' \
  --region '<region>'
```

앞선 작업에서는 VM 내부에서 `TAEWAN.KIM` 컴파트먼트 조회가 성공했다.

## 17. SSH Config 등록

로컬 `~/.ssh/config`에 VM alias를 등록한다.

```sshconfig
Host <vm_name>
    HostName <public_ip>
    User opc
    IdentityFile <ssh_private_key_file>
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

앞선 작업에서는 다음 alias를 등록했다.

```sshconfig
Host taewan-ol9-dev-20260525 taewan-ol9-dev
    HostName <public_ip>
    User opc
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

이후 최소 입력으로 접속할 수 있다.

```bash
ssh <vm_name>
```

예시:

```bash
ssh taewan-ol9-dev
```

## 18. 최종 검증

설치된 도구 버전을 확인한다.

```bash
git --version
python3.12 --version
node --version
npm --version
oci --version
uv --version
claude --version
codex --version
```

앞선 작업의 검증 결과:

```text
git version 2.47.3
Python 3.12.12
Node.js v24.14.1
npm 11.11.0
OCI CLI 3.83.0
uv 0.11.16
Claude Code 2.1.150
codex-cli 0.133.0
```

OCI 리소스도 확인한다.

```bash
oci compute instance get \
  --instance-id '<instance_ocid>' \
  --region '<region>'

oci bv boot-volume get \
  --boot-volume-id '<boot_volume_ocid>' \
  --region '<region>'
```

앞선 작업의 boot volume 검증 결과:

```text
size-in-gbs = 100
vpus-per-gb = 10
lifecycle-state = AVAILABLE
```

Launch options에서 PV in-transit encryption도 확인했다.

```text
is-pv-encryption-in-transit-enabled = true
```

## 19. VCN이 없는 경우 기본 Public VCN 생성

선택한 컴파트먼트에 VCN이 하나도 없으면 VM 생성 전에 기본 public VCN을 먼저 만든다.

시작 전에 사용자에게 다음 취지의 메시지를 출력한다.

```text
선택한 컴파트먼트에 VCN이 없어 VM 생성 전에 기본 public VCN, internet gateway, route rule, public subnet을 먼저 생성합니다.
```

기본 CIDR 예시:

```text
VCN CIDR: 10.0.0.0/16
Public subnet CIDR: 10.0.0.0/24
```

VCN 생성:

```bash
oci network vcn create \
  --compartment-id '<compartment_ocid>' \
  --region '<region>' \
  --display-name '<vm_name>-vcn' \
  --dns-label '<dns_label>' \
  --cidr-block '10.0.0.0/16' \
  --wait-for-state AVAILABLE
```

Internet Gateway 생성:

```bash
oci network internet-gateway create \
  --compartment-id '<compartment_ocid>' \
  --region '<region>' \
  --vcn-id '<vcn_ocid>' \
  --display-name '<vm_name>-igw' \
  --is-enabled true \
  --wait-for-state AVAILABLE
```

Route Table 생성:

```bash
oci network route-table create \
  --compartment-id '<compartment_ocid>' \
  --region '<region>' \
  --vcn-id '<vcn_ocid>' \
  --display-name '<vm_name>-public-rt' \
  --route-rules '[{"cidrBlock":"0.0.0.0/0","networkEntityId":"<internet_gateway_ocid>"}]' \
  --wait-for-state AVAILABLE
```

Public subnet 생성:

```bash
oci network subnet create \
  --compartment-id '<compartment_ocid>' \
  --region '<region>' \
  --vcn-id '<vcn_ocid>' \
  --display-name '<vm_name>-public-subnet' \
  --dns-label 'public' \
  --cidr-block '10.0.0.0/24' \
  --route-table-id '<route_table_ocid>' \
  --prohibit-public-ip-on-vnic false \
  --wait-for-state AVAILABLE
```

생성 후에는 이 VCN과 public subnet을 VM 생성 절차의 입력값으로 사용한다.
