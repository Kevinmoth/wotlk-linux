# WSL runbook: the client under WSL (Dozen / GPU-PV)

Everything here is environment configuration. The only client-side change the
WSL session needed is the Dozen terrain fallback (see `KNOWN_ISSUES_VULKAN.md`).

## The four pieces

| Piece | Why |
|---|---|
| `SDL_VIDEODRIVER=x11` | WSLg's Weston has no Wayland pointer-lock: SDL3 relative-mouse mode fails silently under Wayland (right-drag camera dead) and window decorations are bare. XWayland provides working grab/relative mode and normal WSLg decorations. `SdlUseWayland()` honors a user-set `SDL_VIDEODRIVER`. |
| Dozen (`microsoft-experimental`), RELEASE build | Hardware Vulkan on WSL is Dozen for every vendor: modern drivers ship no `libGLX_nvidia.so.0`. A debug Mesa build validates Vulkan objects on every call (slow) and its `vk_object_base_assert_valid` aborts at shutdown - confirmed via the client's own `Errors/*.txt` + `addr2line` (RIP inside `libvulkan_dzn.so`, stack: `BeginCloseGame -> DeviceDestroy -> DestroyInstance -> DestroyDevice -> Collect`). |
| `VK_DRIVER_FILES=<dzn icd>` | Keeps llvmpipe (software, ~4 FPS) out of device enumeration. |
| `libasound2-plugins` + `/etc/asound.conf` (`pcm.!default { type pulse }`) + `PULSE_SERVER=unix:/mnt/wslg/PulseServer` | FMOD opens the ALSA default device; WSLg audio is PulseAudio. Without this the log fills with ALSA card errors. |

## Launch

```bash
export SDL_VIDEODRIVER=x11
export VK_DRIVER_FILES=/usr/share/vulkan/icd.d/dzn_icd.x86_64.json
export PULSE_SERVER=unix:/mnt/wslg/PulseServer
./WowClient64 -datadir /path/to/3.3.5a
```

## Building Mesa Dozen (release)

```bash
git clone --depth 1 -b mesa-26.0.8 https://gitlab.freedesktop.org/mesa/mesa.git
meson setup build-dzn-rel -Dvulkan-drivers=microsoft-experimental \
  -Dgallium-drivers=[] -Dtools=[] -Dplatforms=x11,wayland \
  -Dglx=disabled -Degl=disabled -Dgbm=disabled -Dopengl=false \
  -Dgles1=false -Dgles2=false -Dllvm=disabled -Dvideo-codecs=[] \
  -Dzstd=disabled -Dbuildtype=release
ninja -C build-dzn-rel
sudo ninja -C build-dzn-rel install
sudo ln -sf /usr/local/share/vulkan/icd.d/dzn_icd.x86_64.json /usr/share/vulkan/icd.d/
```

## Measured (GTX 1650, 2026-10-24)

- World loads reliably with the multipass terrain fallback; ~20 FPS on the
  debug driver, more on release; already-low settings (farclip 177).
- The same machine's Windows client: ~380 FPS. The WSL costs are Dozen
  (Vulkan-to-D3D12), GPU-PV and WSLg presentation - not the port.
- Shutdown is clean with the release driver (the shutdown assert was
  debug-only).
- The client honors its `Crash.txt` + `addr2line` path: keep `RelWithDebInfo`
  when debugging, the binary carries full symbols.
