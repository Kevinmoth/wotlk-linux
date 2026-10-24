# wotlk-linux

Port a **Linux nativo** del cliente decompilado de **World of Warcraft 3.3.5a (build 12340, junio de 2010)**.

Este repositorio ([Kevinmoth/wotlk-linux](https://github.com/Kevinmoth/wotlk-linux), rama `port/linux`) parte
de la decompilación C++ de [SatyPardus/wowdecomp](https://github.com/SatyPardus/wowdecomp) —cada función
reconstruida desde el binario original conserva su etiqueta `// OFFSET:`— y del trabajo de plataforma de
[RosemyneH/wowdecomp](https://github.com/RosemyneH/wowdecomp), del que proviene **gran parte del port**
(ver [Créditos](#créditos)).

**Experimental**: la base se declara a sí misma inestable; espere regresiones. **No se incluyen datos del
juego**: necesitas un cliente 3.3.5a (12340) propio.

## Qué trae la base

| Área | Estado |
|---|---|
| Renderer | **Vulkan**, único backend de Gx en Linux. FFP emulado en GLSL→SPIR-V embebido (`Shaders/Generated`), device con split `Unix/`/`Windows/` |
| Plataforma | `Os/Linux` completo: **SDL3** para ventana, teclado/ratón y gamepad; ventana **Wayland** (embed propio + xdg-shell) o **X11** según la sesión |
| Audio | FMOD Ex decompilado con salida **ALSA** (`SoundEngine/fmodex/linux/`) |
| Rendimiento | Job pool multihilo (`Engine/Source/Base/Job/`) para la preparación de frame (terreno, M2, UI) |
| Herramientas | `Tools/dev-station.sh` y servidor local **AzerothCore via Docker** (`Tools/local-server/`) para pruebas |

Extras heredados de la base, fuera del objetivo de este port: addons WASM opcionales (se compilan fuera
si no hay Wasmtime en el sistema), streaming de `Data` por CDN y soporte Android/macOS experimental.
`--target WowClient` no compila ninguna de esas piezas.

## Progreso de la decompilación

Medido contra el binario 12340 el 2026-10-15 (baseline de upstream). No indica cuánto del juego funciona:
una función portada puede comportarse de forma distinta al original.

| | Porteadas | Total | Porcentaje |
|---|---:|---:|---:|
| Funciones | 24.515 | 27.157 | 90,3 % |
| Bytes de código | 5.270.186 | 5.656.573 | 93,2 % |

## Requisitos (Linux)

- Un cliente **World of Warcraft 3.3.5a (12340)**: su carpeta `Data`.
- **CMake 3.24+**, toolchain **C++17** (Clang o GCC), Ninja.
- Paquetes (los mismos que usa el CI): `ninja-build g++ libsdl3-dev libwayland-dev libcurl4-openssl-dev
  libasound2-dev libvulkan-dev libxvidcore-dev`. `libsdl3-dev` está en Ubuntu 25.04 y posteriores (el CI
  usa 26.04); en distros anteriores, compila SDL3 desde fuente.
- Loader y drivers **Vulkan** (Mesa sirve).

## Compilación

Los builds in-source se rechazan: usa un directorio `build/` aparte. `--target WowClient` produce solo el
cliente de juego.

```bash
git clone -b port/linux https://github.com/Kevinmoth/wotlk-linux.git
cd wotlk-linux

cmake -S . -B build/linux -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DWOWDECOMP_DISABLE_SIGNATURE_CHECKS=ON
cmake --build build/linux --target WowClient -j"$(nproc)"
```

El binario queda en **`bin/Linux/WowClient64`**. Para Release (`-O3 -DNDEBUG`) usa otro directorio
(p. ej. `build/linux-release`) con `CMAKE_BUILD_TYPE=Release`.

Opciones de CMake relevantes:

| Opción | Por defecto | Efecto |
|---|---|---|
| `WOWDECOMP_ENABLE_VULKAN` | `ON` | Compila el backend Vulkan |
| `WOWDECOMP_DISABLE_SIGNATURE_CHECKS` | `OFF` | Omite las firmas de MPQ y `.toc.sig` (datos o Interface modificados) |
| `WOWDECOMP_WASM_ADDONS` | auto | `OFF` fuerza los addons WASM fuera del binario |

Regenerar el SPIR-V embebido (requiere el `glslc` indicado en
`Engine/Source/Gx/CGxDeviceVulkan/Shaders/glslc.version`):

```bash
cmake --build build/linux --target GxVulkanShadersRegenerate
```

El árbol incluye los workflows de CI de la base: `linux-x64` compila `WowClient` en ubuntu-26.04 en cada
push. En un fork hay que habilitarlos en la pestaña **Actions**.

## Ejecución

1. Copia la carpeta `Data` de tu 3.3.5a junto al binario (o arranca con `-datadir /ruta/al/cliente`).
2. Apunta `Data/<locale>/realmlist.wtf` a tu realm.
3. Lanza `bin/Linux/WowClient64` desde ese directorio.

Notas:

- Sesión Wayland → ventana Wayland; sesión X11 → X11. `SDL_VIDEODRIVER` solo para forzar a mano.
- Gamepad conectado activo por defecto (`Joystick 1`), con el layout de retail.
- Servidor local de pruebas: `Tools/local-server/start-docker.sh` (AzerothCore via Docker).

## Estructura (relevante)

| Ruta | Contenido |
|---|---|
| `Engine/Source/Os/Linux/` | Capa de plataforma Linux (SDL3, Wayland embed, protocolo xdg-shell) |
| `Engine/Source/Gx/CGxDeviceVulkan/` | Device Vulkan, shaders FFP, glue Unix/Windows |
| `Engine/Source/SoundEngine/fmodex/linux/` | Salida ALSA del FMOD Ex decompilado |
| `Engine/Source/Base/Job/` | Job pool multihilo |
| `Engine/Source/`, `WoW/Source/` | El resto del motor y del juego (layout del cliente original) |
| `Tools/WowClient/` | Target del ejecutable |
| `Tools/local-server/` | Docker AzerothCore para pruebas |
| `docs/` | Documentación de la base (gráficos, plataformas, rendimiento); `docs/port/` con las incidencias conocidas de este fork |

## Linaje de este fork

- `port/linux` (rama por defecto): importación en un único commit del árbol de `RosemyneH/wowdecomp`
  (`ebf18baf`, 2026-10-20), más las correcciones de gromchek (`va_end`, bounds checks, `sizeof` en memset)
  y `docs/port/KNOWN_ISSUES_VULKAN.md` con el registro de incidencias.
- `main`: espejo sin tocar de `SatyPardus/wowdecomp`, para sincronizaciones futuras.
- `base/warcraftxl`: base anterior (upstream + device Vulkan de WarcraftXL), archivada como referencia.

## Créditos

- [SatyPardus/wowdecomp](https://github.com/SatyPardus/wowdecomp) y todo el mundo acreditado allí: la decompilación.
- **[RosemyneH](https://github.com/RosemyneH)** — un agradecimiento extra por **gran parte del port**: la capa
  `Os/Linux`, el renderer Vulkan, el audio y la infraestructura de CI de los que parte este proyecto.
- [brian8544](https://github.com/brian8544) por el cliente de streaming de 3.3.5a y `mod-streamingclient` (GPL-2.0).
- [binana](https://github.com/thunderbrewhq/binana), [thunderbrew](https://github.com/thunderbrewhq/thunderbrew),
  [whoa](https://github.com/whoahq/whoa), TOMRUS (por el IDB inicial) y la comunidad de modding de WoW.
- Discord de wowdecomp: https://discord.gg/DsZMGUD8aT
