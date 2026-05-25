# Codex Skill GitHub 관리 및 Mac 설치 가이드

여러 개의 Codex skill을 하나의 GitHub repository에서 관리하려면, **Codex가 실제로 읽는 skill 폴더**와 **사람이 읽는 문서**를 분리하는 구조가 가장 깔끔합니다.

Codex skill 내부는 최대한 얇게 유지하고, 사용 설명서와 HTML 문서는 repository의 `docs/` 디렉터리에 두는 방식을 권장합니다.

## 추천 Repository 구조

```text
my-codex-skills/
├── README.md
├── skills/
│   ├── oci-helper/
│   │   ├── SKILL.md
│   │   ├── agents/
│   │   │   └── openai.yaml
│   │   ├── references/
│   │   │   └── usage.md
│   │   ├── scripts/
│   │   └── assets/
│   └── report-writer/
│       ├── SKILL.md
│       ├── agents/
│       │   └── openai.yaml
│       └── references/
│           └── usage.md
├── docs/
│   ├── index.md
│   ├── oci-helper/
│   │   ├── usage.md
│   │   └── usage.html
│   └── report-writer/
│       ├── usage.md
│       └── usage.html
└── scripts/
    ├── install.sh
    └── validate-skills.sh
```

## 각 디렉터리의 역할

### `skills/`

실제로 Codex에 설치할 skill 폴더들을 둡니다.

각 skill은 최소한 다음 파일을 가져야 합니다.

```text
skills/my-skill/
└── SKILL.md
```

`SKILL.md`는 Codex가 skill을 인식하고 실행할 때 읽는 핵심 파일입니다.

### `docs/`

사람이 읽는 문서를 둡니다.

예를 들어 skill별 사용법, 설치법, 예제, HTML 문서 등을 여기에 둡니다.

```text
docs/
└── my-skill/
    ├── usage.md
    └── usage.html
```

Codex skill 내부에 사람용 `README.md`, `INSTALLATION_GUIDE.md`, `QUICK_REFERENCE.md` 같은 문서를 많이 넣는 것은 권장하지 않습니다. Codex가 읽어야 할 내용과 사람이 읽을 문서를 분리하는 편이 관리하기 좋습니다.

### `references/`

Codex가 작업 중 필요할 때만 참고할 상세 문서를 둡니다.

예:

```text
skills/my-skill/
└── references/
    ├── usage.md
    ├── api.md
    └── policy.md
```

`SKILL.md`에는 핵심 workflow만 짧게 쓰고, 긴 예제나 상세 설명은 `references/`로 분리하는 것이 좋습니다.

### `scripts/`

반복 실행이 필요한 스크립트를 둡니다.

예:

```text
skills/my-skill/
└── scripts/
    └── generate_report.py
```

또는 repository 전체 설치/검증용 스크립트는 최상위 `scripts/`에 둡니다.

### `assets/`

템플릿, 이미지, 예제 파일, 폰트 등 skill이 출력물을 만들 때 사용할 리소스를 둡니다.

## `SKILL.md` 기본 예시

모든 skill은 `SKILL.md` 파일을 가져야 하며, 맨 위에 YAML frontmatter가 필요합니다.

```markdown
---
name: my-skill
description: Use this skill when the user asks to create, review, or transform a specific kind of artifact.
---

# My Skill

## Workflow

1. 사용자의 요청을 확인한다.
2. 필요한 경우 `references/usage.md`를 읽는다.
3. 기존 repository 패턴을 우선 따른다.
4. 결과물을 생성하거나 수정한다.
5. 가능한 경우 검증한다.

## References

- 일반 사용법이 필요하면 `references/usage.md`를 읽는다.
- API 세부사항이 필요하면 `references/api.md`를 읽는다.
```

`description`은 매우 중요합니다. Codex는 이 설명을 보고 어떤 상황에서 skill을 사용할지 판단합니다.

## Mac에 설치하는 방법

가장 단순하고 관리하기 좋은 방식은 GitHub repository를 clone한 뒤, 각 skill 폴더를 `~/.codex/skills`에 symlink로 연결하는 것입니다.

### 1. Repository clone

```bash
git clone https://github.com/<owner>/my-codex-skills.git
cd my-codex-skills
```

### 2. Codex skills 디렉터리 생성

```bash
mkdir -p ~/.codex/skills
```

### 3. Skill symlink 생성

```bash
ln -s "$(pwd)/skills/oci-helper" ~/.codex/skills/oci-helper
ln -s "$(pwd)/skills/report-writer" ~/.codex/skills/report-writer
```

symlink 방식을 쓰면 GitHub repository에서 `git pull`만 해도 설치된 skill이 함께 최신화됩니다.

### 4. 설치 확인

```bash
ls ~/.codex/skills
```

### 5. Codex 재시작

새 skill을 인식하려면 Codex 앱을 재시작합니다.

## 설치 스크립트 예시

repository에 `scripts/install.sh`를 두면 여러 skill을 한 번에 설치할 수 있습니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

mkdir -p "$CODEX_SKILLS_DIR"

for skill_dir in "$REPO_ROOT"/skills/*; do
  [ -d "$skill_dir" ] || continue

  skill_name="$(basename "$skill_dir")"
  target="$CODEX_SKILLS_DIR/$skill_name"

  if [ -e "$target" ]; then
    echo "skip: $skill_name already exists"
  else
    ln -s "$skill_dir" "$target"
    echo "installed: $skill_name"
  fi
done

echo "Restart Codex to pick up new skills."
```

실행 방법:

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

## Skill 업데이트 방법

symlink 방식으로 설치했다면 업데이트는 간단합니다.

```bash
cd my-codex-skills
git pull
```

이후 Codex를 재시작하면 최신 skill 내용이 반영됩니다.

## 운영 팁

- `skills/` 아래에는 실제 설치 가능한 skill만 둡니다.
- 사람용 가이드는 `docs/`에 둡니다.
- 각 skill의 `SKILL.md`는 짧고 명확하게 유지합니다.
- 긴 예시, 정책, API 설명은 `references/`로 분리합니다.
- HTML 문서는 가능하면 `docs/*.md`에서 생성되게 해서 중복 관리를 줄입니다.
- `description`에는 skill이 사용되어야 하는 상황을 구체적으로 씁니다.
- 설치 후에는 Codex를 재시작해야 새 skill이 인식됩니다.

## 권장 작성 원칙

Codex skill은 사람이 읽는 매뉴얼이라기보다, Codex가 특정 작업을 안정적으로 수행하기 위한 작업 지침입니다.

따라서 다음 원칙을 권장합니다.

1. `SKILL.md`에는 핵심 workflow만 둡니다.
2. 상세 문서는 `references/`로 분리합니다.
3. 사람이 읽는 문서는 `docs/`로 분리합니다.
4. 반복적이고 실수하기 쉬운 작업은 `scripts/`로 자동화합니다.
5. 템플릿이나 이미지 같은 리소스는 `assets/`로 분리합니다.
