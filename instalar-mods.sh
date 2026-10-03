#!/usr/bin/env bash
# Instalador de mods de CPland para ElyPrismLauncher (Linux)
# Uso:
#   bash instalar-mods.sh                 -> usa el Mods-CPLand*.zip más reciente de Descargas
#   bash instalar-mods.sh archivo.zip     -> usa ese zip
#   bash instalar-mods.sh --limpiar       -> borra los .jar viejos antes de instalar
set -e

LIMPIAR=0
ZIP=""
for arg in "$@"; do
  case "$arg" in
    --limpiar) LIMPIAR=1 ;;
    *) ZIP="$arg" ;;
  esac
done

# Carpeta de datos (respeta XDG si está configurado)
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
INST="$DATA/ElyPrismLauncher/instances/1.21.1"

# Carpeta de descargas (Downloads, Descargas, etc.)
DL="$(xdg-user-dir DOWNLOAD 2>/dev/null || true)"
if [ -z "$DL" ] || [ "$DL" = "$HOME" ] || [ ! -d "$DL" ]; then
  for d in "$HOME/Downloads" "$HOME/Descargas"; do
    if [ -d "$d" ]; then DL="$d"; break; fi
  done
fi

# Buscar el zip si no se indicó uno (cualquier versión, sin importar mayúsculas)
if [ -z "$ZIP" ]; then
  shopt -s nocaseglob nullglob
  zips=("$DL"/mods-cpland*.zip)
  shopt -u nocaseglob nullglob
  if [ "${#zips[@]}" -gt 0 ]; then
    ZIP="$(ls -t "${zips[@]}" | head -n1)"
  fi
fi

[ -n "$ZIP" ] && [ -f "$ZIP" ] || { echo "No encontré ningún Mods-CPLand*.zip en: $DL"; exit 1; }
[ -d "$INST" ] || { echo "No existe la instancia: $INST"; exit 1; }
echo "Usando: $ZIP"

# Prism usa ".minecraft" o "minecraft" según la versión
if [ -d "$INST/.minecraft" ]; then MC="$INST/.minecraft"; else MC="$INST/minecraft"; fi
mkdir -p "$MC/mods"

if [ "$LIMPIAR" -eq 1 ]; then
  rm -f "$MC/mods/"*.jar
  echo "Mods viejos eliminados."
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if command -v unzip >/dev/null 2>&1; then
  unzip -q -o "$ZIP" -d "$TMP"
else
  python3 -m zipfile -e "$ZIP" "$TMP"
fi

find "$TMP" -name '*.jar' -exec cp -f {} "$MC/mods/" \;

echo "Mods instalados en: $MC/mods"
