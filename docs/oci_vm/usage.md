# OCI VM Skill

`oci_vm`은 OCI CLI로 Oracle Cloud VM을 생성하고 초기 설정하는 Codex skill입니다.

이 skill은 일반 VM 요청이 아니라 `oci_vm`을 명시적으로 호출할 때만 사용되도록 설계되어 있습니다.

## 최소 입력

```text
oci_vm: <vm 이름>으로 VM 생성
```

## 기본값

- Compartment: `TAEWAN.KIM`
- Region: `chicago` (`us-chicago-1`)
- CPU type: `E5`
- CPU: `2`
- Memory: `CPU * 15GB`
- Boot volume: `100GB`
- Image: latest Oracle Linux 9
- Subnet: selected VCN's public subnet

## 예시

```text
oci_vm: dev-vm-01 생성
```

```text
oci_vm: dev-vm-01 생성, vcn aitwvcn, cpu 4, memory 60GB
```

