# Vulkan backend: lineage and known issues

## Lineage

This branch is based on a single-commit import of RosemyneH/wowdecomp's `main`
(`ebf18baf`, 2026-10-20). Its Vulkan backend (`Engine/Source/Gx/CGxDeviceVulkan`,
with the `Unix/` and `Windows/` platform split and FFP emulation in embedded
GLSL-to-SPIR-V under `Shaders/`) is a **separate implementation** from the
WarcraftXL device of upstream's `vulkan` branch (PR #11) used by our previous
base. The previous base (upstream main + WarcraftXL Vulkan + the fixes below)
is archived at `base/warcraftxl`.

## Known issues

- Upstream Vulkan PRs **#40** (FFX glow flicker) and **#42** (distant terrain
  white instead of fog colour) are defects of the **WarcraftXL device**. They
  do **not** apply to this tree: do not debug them here.
- This base is "extremely experimental" per its own README: regressions are
  expected. The fork's own documentation lives in `docs/` (`graphics.md`,
  `platforms.md`, `performance.md`, `world.md`, `fonts.md`) and its wiki.
- Upstream-main commits from 2026-10-17 to 2026-10-23 (187 commits: deadlock
  fix, font-cache rows, portrait-cache dirty flag, override-sky sync,
  talent-preview ranks, and more) are **not** in this base. Missing them is a
  pending sync task, not a port bug.

## Re-applied corrections

On top of the import, gromchek's fixes (upstream PR #34) were re-applied:

- `fix: missing va_end` (BattlenetUI / BattlenetLogin)
- `fix: array bounds check` (CommentatorFrame, QuestFrame, TalentInfo, DayNight,
  FriendList, FriendList_Scripts)
- `fix: use sizeof for memset` (ValidateName)

## Rules for the port

- On any visual or stability issue on Linux, first check whether it reproduces
  in RosemyneH's own client (their CI binary) to tell fork defects from our
  changes; record anything confirmed here.
