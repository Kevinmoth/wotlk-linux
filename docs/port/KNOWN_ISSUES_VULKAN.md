# Known issues of the Vulkan backend

Visual defects that exist in the upstream Vulkan backend (`Engine/Source/Gx/CGxDeviceVulkan`, the
`vulkan` branch, PR #11 by WarcraftXL/iThorgrim) since before the Linux port began. Recorded so
they are not mistaken for Linux-port regressions when testing.

| Symptom | Upstream PR | Author | State on 2026-10-24 |
|---|---|---|---|
| Distant terrain renders white instead of the fog colour | [#42](https://github.com/SatyPardus/wowdecomp/pull/42) | DeltaTho | open |
| FFX glow flickers while the camera moves | [#40](https://github.com/SatyPardus/wowdecomp/pull/40) | DeltaTho | open |

Rules for the port:

- Seeing either symptom on Linux means a Vulkan backend bug, not a port regression: check the
  upstream PR before debugging the port.
- If we cherry-pick either PR, or a sync with upstream brings them in, update this file.

Both PRs target the `vulkan` branch upstream; neither is part of `port/linux` as created
(merge commit e1e16124).
