# Guía de prueba — WoW 3.3.5a en Arch Linux (nativo)

Esta guía es para probar el **release `continuous`** en Arch Linux nativo (no WSL, no Dozen).
El cliente es un port del cliente 3.3.5a (build 12340) y **no incluye los datos del juego**: necesitás tu propia carpeta `Data`.

Si algo falla, seguí la sección [Problemas frecuentes](#problemas-frecuentes) y mandá la salida de terminal que se pide al final.

---

## 1. Requisitos

| Requisito | Cómo comprobarlo |
|---|---|
| Arch Linux actualizado | `sudo pacman -Syu` |
| glibc ≥ 2.43 | `ldd --version \| head -1` (Arch estable hoy trae 2.44) |
| GPU con driver Vulkan | `vulkaninfo --summary` |
| Cliente WoW 3.3.5a (12340) | tu carpeta `Data` con los `.MPQ` |
| ~100 MB libres | el binario pesa ~59 MB |

> **Actualizá Arch antes de probar.** El binario se compila en Ubuntu 26.04 y pide `GLIBC_2.43`.
> Un Arch viejo falla con `GLIBC_2.43 not found`. `sudo pacman -Syu` lo resuelve.

---

## 2. Instalar dependencias

Copiá y pegá **el bloque de tu GPU** (o los dos si tenés gráficos híbridos):

```bash
# Base (obligatorio)
sudo pacman -S --needed sdl3 alsa-lib curl wayland libxkbcommon xvidcore \
                     vulkan-icd-loader vulkan-tools pipewire-alsa
```

```bash
# AMD (Radeon / APU)
sudo pacman -S --needed vulkan-radeon
```

```bash
# Intel (iGPU / Arc)
sudo pacman -S --needed vulkan-intel
```

```bash
# NVIDIA propietario
sudo pacman -S --needed nvidia-utils
# (y el módulo del kernel: nvidia-open / nvidia-lts / nvidia, según tu caso)
```

```bash
# NVIDIA con nouveau (open source)
sudo pacman -S --needed vulkan-nouveau
```

**Qué hace cada paquete**

| Paquete | Para qué |
|---|---|
| `sdl3` | ventana, input, audio y carga de Vulkan (`libSDL3.so.0`) |
| `alsa-lib` | salida de audio del motor (`libasound.so.2`) |
| `curl` | descargas / CDN (`libcurl.so.4`) |
| `wayland` | backend Wayland (`libwayland-server.so.0`) |
| `libxkbcommon` | teclado (`libxkbcommon.so.0`) |
| `xvidcore` | videos (`libxvidcore.so.4`) |
| `vulkan-icd-loader` | cargador de Vulkan (`libvulkan.so.1`, se carga en runtime) |
| `vulkan-tools` | `vulkaninfo`, para diagnosticar |
| `pipewire-alsa` | puente ALSA → PipeWire (sin esto no hay audio en Arch con PipeWire) |
| `vulkan-radeon` / `vulkan-intel` / `nvidia-utils` | driver Vulkan real de tu GPU |

> Si usás PulseAudio en vez de PipeWire, instalá `pulseaudio-alsa` en lugar de `pipewire-alsa`.

---

## 3. Verificar Vulkan (antes de abrir el juego)

```bash
vulkaninfo --summary
```

Tiene que listar al menos un `GPU0` con `deviceName` y `apiVersion`. Ejemplo sano:

```
Devices:
========
GPU0:
    apiVersion         = 1.4.x
    deviceName         = AMD Radeon RX ...
    driverName         = AMD open-source driver
```

Si ves `ERROR: [Loader Message] ... Found no drivers!`, falta el driver de tu GPU (paso 2).
**El cliente no arranca sin Vulkan**: ahora muestra un mensaje claro, pero primero comprobá esto.

---

## 4. Descargar el cliente

```bash
mkdir -p ~/wow && cd ~/wow
curl -L -o wow.tar.gz \
  https://github.com/Kevinmoth/wotlk-linux/releases/download/continuous/wowdecomp-linux-x86_64.tar.gz
tar xzf wow.tar.gz
chmod +x WowClient64
```

El tarball trae `WowClient64`, `LEEME.txt` y `run-wow.sh`. **No trae `Data`.**

---

## 5. Preparar los datos

1. Copiá la carpeta `Data` de tu cliente 3.3.5a **junto al binario**:

   ```
   ~/wow/
   ├── WowClient64
   ├── LEEME.txt
   ├── run-wow.sh
   └── Data/
       ├── common.MPQ
       ├── common-2.MPQ
       ├── expansion.MPQ
       ├── lichking.MPQ
       └── enUS/
           ├── locale-enUS.MPQ
           ├── expansion-locale-enUS.MPQ
           ├── lichking-locale-enUS.MPQ
           └── realmlist.wtf
   ```

2. Si tus datos están en otra ruta, no los muevas: arrancá con `-datadir`.

3. Editá `Data/<locale>/realmlist.wtf`:

   ```
   set realmlist tu.servidor.com
   ```

### ⚠️ Mayúsculas y minúsculas (crítico)

Linux distingue mayúsculas. El cliente busca **exactamente**:

- `Data` (no `data`)
- `common.MPQ`, `common-2.MPQ`, `expansion.MPQ`, `lichking.MPQ` (no `.mpq`)
- `enUS` / `esES` / `esMX` / `deDE` / `frFR` (no `enus`)
- `locale-enUS.MPQ`, `expansion-locale-enUS.MPQ`, `lichking-locale-enUS.MPQ`

Si copiaste los datos desde un disco NTFS/exFAT (Windows), los nombres pueden haber quedado en minúsculas.
Comprobalo así:

```bash
cd ~/wow
ls -l Data Data/enUS
```

Si `Data` o los `.MPQ` están en minúsculas, renombralos a la forma canónica. Ejemplo:

```bash
mv Data data_tmp && mv data_tmp Data
mv Data/common.mpq Data/common.MPQ   # repetir con cada MPQ
mv Data/enus Data/enUS               # repetir con el locale correcto
```

Cuando falta o está mal nombrado un archivo, el cliente lo dice en la terminal:

```
Missing or corrupted data: Failed to open archive common.MPQ. (looked for: /home/vos/wow/Data/common.MPQ)
```

---

## 6. Ejecutar

```bash
cd ~/wow
./run-wow.sh
```

o directamente:

```bash
./WowClient64 -windowed
```

| Flag | Efecto |
|---|---|
| `-windowed` | fuerza ventana (recomendado para la primera prueba) |
| `-datadir /ruta/al/cliente` | usa esa carpeta como raíz de datos (absoluta o relativa) |
| `-fullscreen` | pantalla completa |

`run-wow.sh` comprueba Vulkan y `Data/` antes de arrancar y pasa los argumentos al cliente.

---

## 7. Dónde escribe el cliente

| Ruta | Contenido |
|---|---|
| `<datadir>/WTF/` | `Config.wtf`, ajustes, addons, cuentas |
| `<datadir>/Cache/` | caché de descargas |
| `<directorio del binario>/Errors/` | `Assert.log` si el motor detecta un fallo interno |

Con `-datadir`, `WTF/` y `Cache/` van a esa carpeta. `Errors/` va **siempre junto al ejecutable**.
Por eso conviene dejar `WowClient64` dentro de la misma carpeta que `Data`.

---

## 8. Problemas frecuentes

### El cliente se cierra al instante y la terminal dice `terminate called without an active exception`

Era un fallo del apagado de emergencia del pool de hilos: ocultaba el error real y devolvía código 134.
Ya está corregido en los builds nuevos. Si lo ves, estás usando un build viejo: descargá de nuevo `continuous`.

### `Missing or corrupted data: Failed to open archive ... (looked for: ...)`

El cliente no encuentra ese archivo. Revisá:
- que `Data` esté en la ruta indicada (o pasá `-datadir`);
- que el nombre tenga **las mayúsculas exactas** del paso 5;
- que el `.MPQ` no esté corrupto (tamaño distinto al original).

### `vulkan: no GPU with Vulkan support was detected` o `VK_ERROR_INCOMPATIBLE_DRIVER`

Falta el driver Vulkan de tu GPU. Instalá `vulkan-radeon` / `vulkan-intel` / `nvidia-utils` y reiniciá la sesión.
Comprobá con `vulkaninfo --summary`.

### `vulkan: could not load libvulkan.so.1`

Falta `vulkan-icd-loader`:

```bash
sudo pacman -S --needed vulkan-icd-loader
```

### `error while loading shared libraries: libSDL3.so.0: cannot open shared object file`

Faltan dependencias. Reinstalá el bloque base del paso 2 y comprobá:

```bash
ldd ./WowClient64 | grep "not found"
```

No debe imprimir nada.

### `GLIBC_2.43 not found`

Arch está desactualizado:

```bash
sudo pacman -Syu
ldd --version | head -1   # tiene que ser 2.43 o mayor
```

### No hay audio

- Con PipeWire: `sudo pacman -S --needed pipewire-alsa` y reiniciá la sesión.
- Con PulseAudio: `sudo pacman -S --needed pulseaudio-alsa`.
- Comprobá que el sink por defecto no esté muteado: `wpctl status` (PipeWire) o `pavucontrol`.

### Wayland: ventana negra o problemas de foco

Forzá X11 para aislar el problema:

```bash
SDL_VIDEODRIVER=x11 ./WowClient64 -windowed
```

Si en X11 funciona y en Wayland no, reportalo indicando sesión y GPU.

### Pantalla completa en un monitor equivocado

Arrancá con `-windowed`, entrá a Opciones → Gráficos y elegí el monitor. Luego podés volver a `-fullscreen`.

---

## 9. Cómo reportar un problema

Adjuntá:

1. Salida completa de la terminal (copiá desde el comando hasta el cierre).
2. `vulkaninfo --summary`.
3. `ldd ./WowClient64`.
4. `ldd --version | head -1`.
5. GPU, driver y sesión (X11 o Wayland): `echo $XDG_SESSION_TYPE`.
6. Si existe, `WTF/Config.wtf` y `Errors/Assert.log`.

Abrí el issue en <https://github.com/Kevinmoth/wotlk-linux/issues> con esos datos.

---

## 10. Incidencias conocidas

- `docs/port/KNOWN_ISSUES_VULKAN.md`: límites de Vulkan/Dozen/WSL y linaje del port.
- `docs/port/WSL_RUNBOOK.md`: entorno WSL (no es el objetivo de esta prueba).
- El release es **alpha**: se espera que falle algo. Lo importante es que el primer error sea claro y reportable.
