# Skill Guide Usage

`skill-guide` skill은 Codex skill을 GitHub repository 구조로 관리하고 Mac에 설치하는 절차를 다룹니다.

상세 가이드는 skill reference 문서에 있습니다.

```text
skills/skill-guide/references/skill_guide.md
```

## 설치

repository 루트에서 다음 명령을 실행합니다.

```bash
bash scripts/install.sh
```

기본 설치는 copy install입니다. 기존 `~/.codex/skills/<skill>` 설치본을 제거하고 repository의 skill을 물리 복사합니다.

개발 중 repository 변경을 즉시 Codex에 반영해야 할 때만 symlink 모드를 사용합니다.

```bash
bash scripts/install.sh --link
```

설치 후 Codex를 재시작합니다.
