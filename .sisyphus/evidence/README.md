# Evidence Directory

Every task in `.sisyphus/plans/odroid-m1s-tinypilot-adapter.md` should save verification evidence here.

## Rules

- Record exact commands and outputs.
- Prefer explicit `BLOCKED` evidence over pass/fail guesses when hardware is unavailable.
- Do not store secrets, passwords, private IP addresses, local-only serial details, or personal logs.
- Do not store large disk images, extracted root filesystems, or kernel build artifacts in this repository.
- Use small text files, checksums, command transcripts, and screenshots only when safe to publish.

## Naming convention

```text
.sisyphus/evidence/task-<N>-<short-slug>.md
.sisyphus/evidence/task-<N>/<artifact-name>.txt
.sisyphus/evidence/final/<review-name>.md
```

Examples:

```text
.sisyphus/evidence/task-1-configfs-design.md
.sisyphus/evidence/task-5-real-device-hid-setup/udc.txt
.sisyphus/evidence/final/release-readiness.md
```
