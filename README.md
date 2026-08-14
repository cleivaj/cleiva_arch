# arch_installer

Instalador de Arch Linux **educativo**: detecta tu hardware y decide qué
paquetes necesitaría una instalación con Hyprland. No instala nada — la
primera versión es solo **detección + decisión** para que entiendas cómo
funciona cada pieza por dentro.

## Cómo funciona

Un instalador no es magia. Es esto:

```
detectar hardware  →  decidir paquetes  →  ejecutar la instalación
     (leer)              (pensar)              (actuar)
```

| Carpeta | Rol |
|---|---|
| `detect/` | Módulos independientes que leen el sistema y emiten hechos en `KEY=VALUE` |
| `decide/` | Árbol de decisión: mapea hechos → paquetes, con la razón de cada uno |
| `lib/` | Helpers: logging (`common.sh`) y búsqueda de paquetes en la API oficial (`api.sh`) |
| `output/` | Resultados generados: hechos, lista de paquetes y reporte explicado |

Cada script de `detect/` se puede correr solo para ver qué detecta:

```bash
./detect/gpu.sh     # → GPU_VENDOR=nvidia (o amd / intel / unknown)
./detect/virt.sh    # → VIRT=none (o kvm, virtualbox, wsl...)
```

## Uso

```bash
./main.sh detect        # hechos de hardware → output/facts.txt
./main.sh decide        # árbol de decisión → output/packages.txt + report.md
./main.sh search hyprland   # busca paquetes en la API de archlinux.org
./main.sh check         # valida la lista contra los repos oficiales (necesita red)
./main.sh all           # detect + decide + check
```

El reporte (`output/report.md`) es lo importante: te dice **por qué** se
eligió cada paquete. Ejemplo: `GPU_VENDOR=nvidia` → `nvidia-utils` "GPU
NVIDIA → utilidades y libGL".

## Cómo funcionan las búsquedas de paquetes

Hay dos niveles, y este proyecto usa el segundo:

1. **`pacman -Ss <nombre>`** — busca en la base de datos local de paquetes
   (solo útil ya dentro de un sistema instalado, tras `pacman -Sy`).
2. **API oficial de archlinux.org** — `lib/api.sh` consulta
   `https://archlinux.org/packages/search/json/?q=<nombre>` y comprueba si
   el paquete existe en los repos oficiales y en qué repo/versión. Es lo
   que usamos en `./main.sh check` para validar la lista antes de instalar.

El JSON se parsea con `grep` a propósito: para comprobar existencia es
suficiente. La herramienta correcta para JSON de verdad es `jq`.

## Filosofía del árbol de decisión

En `decide/packages.sh` cada regla es **"si (hecho) entonces (paquete) por
(razón)"**:

```bash
case "$GPU_VENDOR" in
  nvidia) add nvidia-utils "GPU NVIDIA → utilidades y libGL" ;;
esac
```

Añadir conocimiento nuevo = añadir un `case`. Ejemplos de reglas ya
incluidas:

- CPU Intel/AMD → `intel-ucode` / `amd-ucode`
- GPU NVIDIA/AMD/Intel → drivers correspondientes
- VM detectada (`systemd-detect-virt`) → drivers genéricos, no específicos
- Bluetooth presente → `bluez bluez-utils`
- Portátil (batería) → `brightnessctl tlp`
- SSD/NVMe → recomendación btrfs; HDD → recomendación ext4

## Roadmap (próximas versiones)

1. **Particionado**: usar `FIRMWARE` (uefi/bios), `DISK_*` y `RAM_GB` para
   generar la tabla de particiones (EFI + root, tamaño de swap).
2. **Instalación real**: `pacstrap`, `arch-chroot`, `mkinitcpio`,
   bootloader (systemd-boot para UEFI, GRUB para BIOS), usuario, locale.
3. **Perfiles**: además de Hyprland, soportar GNOME/KDE/i3, y perfiles
   (dev, gaming, minimal).
4. **Detección más fina**: elegir entre `nvidia` y `nvidia-open` según el
   modelo exacto de GPU (se puede leer del ID de dispositivo PCI).

Para probar la instalación completa sin romper tu sistema: **QEMU**.
```bash
# desde el ISO de Arch montado en una VM
qemu-system-x86_64 -enable-kvm -cdrom archlinux.iso -boot d -m 4G
```

## Referencias

- [archinstall](https://github.com/archlinux/archinstall) — instalador
  oficial (Python): el árbol de decisión real más grande que existe.
- [Arch Wiki: Installation guide](https://wiki.archlinux.org/title/Installation_guide)
- [Arch Wiki: pacman](https://wiki.archlinux.org/title/Pacman)
- [API de paquetes de archlinux.org](https://wiki.archlinux.org/title/DeveloperWiki:Package_search)
