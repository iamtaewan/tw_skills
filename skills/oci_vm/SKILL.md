---
name: oci_vm
description: Use this skill only when the literal token `oci_vm` is present in the user's request. Do not use this skill for generic OCI, VM, Compute, cloud provisioning, infrastructure, or server requests that do not include `oci_vm`.
---

# OCI VM

## Trigger Guard

Use this skill only when the user's request explicitly contains `oci_vm`.
If `oci_vm` is not explicitly present, do not use this skill.

## Required Input

- VM name

If the VM name is missing, ask for it before doing any OCI lookup or creation.

## Defaults

- Compartment name: `TAEWAN.KIM`
- Region alias: `chicago`
- OCI region: `us-chicago-1`
- CPU type: `E5`
- Shape mapping: `E5` -> `VM.Standard.E5.Flex`, `E6` -> `VM.Standard.E6.Flex`
- CPU: `2`
- Memory: `CPU * 15GB`
- Boot volume: `100GB`
- Image: latest Oracle Linux 9 image for the selected region and shape
- Subnet: selected VCN's public subnet

## Workflow

1. Confirm the request explicitly invoked `oci_vm`.
2. Confirm the VM name. Stop and ask if missing.
3. Read `references/oci-vm-creation-procedure.md` for OCI CLI commands and verification details.
4. Calculate defaults for compartment, region, shape, CPU, memory, boot volume, image, VCN, and subnet.
5. Verify local OCI CLI, `~/.oci/config`, and API key files exist.
6. Resolve compartment OCID from the compartment name.
7. Resolve the region. `chicago` means `us-chicago-1`.
8. Resolve shape from CPU type.
9. Resolve the latest Oracle Linux 9 image OCID for the region and shape.
10. Resolve VCN:
    - If a VCN name is provided, use that VCN.
    - If no VCN name is provided and exactly one VCN exists in the compartment, use it.
    - If no VCN name is provided and two or more VCNs exist, ask the user for the VCN name.
    - If no VCN exists, print a start message that a default public VCN must be created first, then create a basic public VCN before continuing.
11. Resolve subnet:
    - If a subnet name is provided, use that subnet.
    - Otherwise use a public subnet where `prohibit-public-ip-on-vnic = false`.
12. Resolve SSH key:
    - Prefer `~/.ssh/id_ed25519.pub`.
    - Otherwise use `~/.ssh/id_rsa.pub`.
    - If neither exists, create `~/.ssh/id_ed25519`.
13. Before launching the VM, show a concise final summary of values to be created and state that OCI resources may incur cost.
14. Launch the VM using OCI CLI.
15. Query public IP and verify SSH connectivity.
16. Install git, tmux, OCI CLI, uv, Python 3.12, Claude Code, and Codex on the VM.
17. If remote OCI CLI use is required, copy `~/.oci/config` and the API key to the VM, fix `key_file`, restrict permissions, and explicitly mention that the API key is a private credential.
18. Test OCI CLI from the VM.
19. Back up local `~/.ssh/config`, then add a host alias so `ssh {vm name}` connects to the VM.
20. Summarize final IPs, SSH command, installed versions, and verification results.

## Safety Rules

- Never launch a VM until the final cost-affecting summary has been shown.
- Never overwrite an existing SSH private key.
- Never edit `~/.ssh/config` without first creating a timestamped backup.
- If multiple compartments, VCNs, or subnets match ambiguously, ask for the exact name instead of guessing.
- Use the repository's existing commands and conventions from the reference document before inventing new commands.
