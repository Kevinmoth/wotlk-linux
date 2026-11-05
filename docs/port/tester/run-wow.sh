#!/usr/bin/env bash
# Lanzador para testers en Arch Linux: comprueba lo basico y abre en ventana.
set -u

cd "$(dirname "$0")" || exit 1

has_datadir=0
for arg in "$@"; do
    case "$arg" in
        -datadir|-datadir=*) has_datadir=1 ;;
    esac
done

fail=0

if [ "$has_datadir" -eq 0 ] && [ ! -d Data ]; then
    echo "AVISO: no hay carpeta Data/ junto al binario."
    echo "       Copia Data de tu cliente 3.3.5a aqui, o arranca con:"
    echo "       ./WowClient64 -datadir /ruta/a/tu/cliente -windowed"
    fail=1
fi

if ! command -v vulkaninfo >/dev/null 2>&1; then
    echo "AVISO: falta vulkan-tools. Instala: sudo pacman -S vulkan-tools"
elif ! vulkaninfo --summary >/dev/null 2>&1; then
    echo "ERROR: Vulkan no funciona en este equipo."
    echo "       Instala el driver de tu GPU:"
    echo "         AMD     -> sudo pacman -S vulkan-radeon"
    echo "         Intel   -> sudo pacman -S vulkan-intel"
    echo "         NVIDIA  -> sudo pacman -S nvidia-utils"
    echo "       Y comprueba con: vulkaninfo --summary"
    fail=1
fi

if command -v ldd >/dev/null 2>&1 && ldd ./WowClient64 2>/dev/null | grep -q "not found"; then
    echo "ERROR: faltan bibliotecas:"
    ldd ./WowClient64 | grep "not found"
    echo "       Instala las dependencias de docs/port/ARCH_GUIDE.md"
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    echo
    echo "Corrige lo anterior o consulta docs/port/ARCH_GUIDE.md"
    exit 1
fi

exec ./WowClient64 -windowed "$@"
