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

## WSL / Dozen (dzn) environment limits - 2026-10-24

The terrain pipeline uses a bindless combined-image-sampler array of
`TerrainSlots = 65536` (update-after-bind + descriptor indexing). Two walls
were confirmed while testing on WSL:

1. Dozen's DXIL compiler asserts on undeclared resource ranges. Fixed in
   this fork by declaring the bound in `FfpTerrain.frag`; semantically
   identical for real drivers.
2. D3D12 hard-caps shader-visible SAMPLER heaps (~2048 descriptors), so
   the 65536-sampler terrain set can never be hosted by Dozen
   (`dzn_descriptor_heap_pool_alloc_slots` assert at world load). This is
   a limit of the D3D12 programming model, not a Mesa bug.

Consequences:
- Without the NVIDIA WSL Vulkan ICD (absent from this machine's stripped
  Windows driver), the only working device on WSL is llvmpipe (software):
  fully playable, ~4 FPS in-world.
- A standard NVIDIA driver install (with WSL graphics components) provides
  the native Vulkan ICD inside WSL and removes both walls.
- Native Linux remains the performance target: Mesa (RADV/ANV) and the
  NVIDIA driver both support the bindless terrain design as-is.

## WSL graphics: definitive landscape - 2026-10-24 (after full 621.01 install)

The "stripped Windows driver" hypothesis was disproved: a full standard
Game Ready 621.01 install on Windows 10 IoT LTSC 2021 ships no
`libGLX_nvidia.so.0` anywhere (DriverStore or lxss). Modern NVIDIA
drivers no longer carry the old WSL GL/Vulkan producer stack: hardware
Vulkan inside current WSL is Dozen (dzn over D3D12 GPU-PV) for every
vendor, and llvmpipe is the software fallback.

Dozen hard limits (Mesa 26.0.8, `src/microsoft/vulkan/dzn_private.h`):
- Shader-visible SAMPLER heap: `D3D12_MAX_SHADER_VISIBLE_SAMPLER_HEAP_SIZE`
  = 2048 descriptors. The terrain bindless set (`TerrainSlots = 65536`
  combined image samplers) can never fit: world-load crash in
  `dzn_descriptor_heap_pool_alloc_slots`.
- CBV/SRV/UAV heap: 1,000,000 (Tier 1).

Paths forward, all open:
- Split-descriptor refactor: declare the terrain array as SAMPLED_IMAGE
  (1M cap) plus a small shared SAMPLER pool (fits the 2048 cap). Real
  fix, upstreamable, makes WSL/Dozen playable.
- llvmpipe: works today end to end, ~4 FPS in-world.
- Native Linux (dual boot / USB / second disk): the port's actual target;
  full Vulkan where the bindless design is supported as-is.

## Result after the Dozen fallback fix - 2026-10-24

With the multipass terrain path active on Dozen, the world loads
reliably (previously a deterministic crash). Measured on WSL/Dozen +
GTX 1650, same data and settings: ~20 FPS in-world, versus ~4 on
llvmpipe and ~380 on the same machine's Windows client. Minor visual
glitches observed under Dozen, pending review. WSLg adds presentation
latency; native Linux remains the performance target.
