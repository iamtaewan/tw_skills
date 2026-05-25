# My Codex Skills

개인 Codex skill을 GitHub repository 형태로 관리하기 위한 작업 공간입니다.

## 구조

```text
my_skills/
├── README.md
├── skills/
│   ├── skill-guide/
│   │   ├── SKILL.md
│   │   ├── agents/
│   │   │   └── openai.yaml
│   │   ├── references/
│   │   │   └── skill_guide.md
│   │   ├── scripts/
│   │   └── assets/
│   └── oci_vm/
│       ├── SKILL.md
│       ├── agents/
│       │   └── openai.yaml
│       ├── references/
│       │   └── oci-vm-creation-procedure.md
│       ├── scripts/
│       └── assets/
├── docs/
│   ├── index.md
│   ├── skill-guide/
│   │   └── usage.md
│   └── oci_vm/
│       └── usage.md
└── scripts/
    ├── install.sh
    └── validate-skills.sh
```

## Skills

- `skill-guide`: Codex skill GitHub 관리 및 Mac 설치 가이드
- `oci_vm`: 명시적으로 `oci_vm`을 호출했을 때 OCI VM 생성 절차 수행

## 설치

```bash
bash scripts/install.sh
```

설치 후 Codex를 재시작하면 새 skill이 인식됩니다.
