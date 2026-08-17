# TODO — step-by-step plan (file by file)

The goal: write, by hand, an Arch installer that **detects hardware and
decides which packages to install** (Hyprland). Each task says *what* to build
and *how to verify it*. You write the code yourself — if you get stuck, ask me
**concepts**, not solutions.

## How to use this plan

- Each task has a **✓ how to verify**: run the indicated command and compare
  with the expected output (the values below are from your real machine).
- Create **one commit per finished file** (`git add <file> && git commit`).
  That gives you clean history and you never lose work.
- If something fails: debug with `bash -x <script>` (shows each step) or add
  a temporary `echo "VAR=$VAR"`.
- Rule for the detection modules: they are **independent** (they don't use
  `lib/`), print `KEY=VALUE` lines, and if a command doesn't exist they must
  not break.

---

## Phase 0 — Fundamentals (30 min)

- [ ] **0.1** Understand the facts format: each module prints `KEY=VALUE`
  (e.g. `CPU_VENDOR=intel`). A single token per value, no spaces. Why?
  Because `main.sh` later does `source output/facts.txt` and that turns each
  line into a shell variable. Try it: create a file with
  `echo "FOO=bar" > /tmp/x` and do `source /tmp/x && echo $FOO`.
- [ ] **0.2** Master the shell you'll use in every file:
  - `$(command)` to capture output
  - `${VAR:-default}` for default values
  - `if [[ ... ]]`, `case ... esac`, `for x in ...; do ...; done`
  - Arrays: `arr=()`, `arr+=("x")`, `${arr[@]}`, `${!arr[@]}` (indices)
  - `set -u` (error if you use an undefined variable) — and find out what
    `set -o pipefail` does (ask yourself: why is it important when chaining
    with `|`?)

---

## Phase 1 — detect/ (10 files)

> Each script: `#!/usr/bin/env bash`, `set -u`. Only prints `KEY=VALUE` lines.
> Run with `bash detect/<name>.sh`.

### 1. `detect/firmware.sh` — the easiest
- Goal: do we boot in UEFI or BIOS?
- Hint: on a UEFI boot the kernel mounts `/sys/firmware/efi`.
- ✓ `bash detect/firmware.sh` → `FIRMWARE=uefi` (your machine)

### 2. `detect/cpu.sh`
- Read `/proc/cpuinfo`, look for the `vendor_id` line. How to extract the last
  field? Hint: `awk '{print $NF}'`.
- `GenuineIntel` → intel, `AuthenticAMD` → amd, anything else → unknown.
- ✓ `bash detect/cpu.sh` → `CPU_VENDOR=amd`

### 3. `detect/ram.sh`
- `free -g` gives RAM in GiB (rounded down). Which column of the `Mem:` line?
  And if `free` doesn't exist? → use `${VAR:-0}`.
- ✓ `bash detect/ram.sh` → `RAM_GB=7` (your real 8 GB: `free -g` rounds)

### 4. `detect/virt.sh`
- `systemd-detect-virt` → `kvm`, `virtualbox`, `wsl`, `none`... What if the
  command doesn't exist? → `unknown`.
- ✓ `bash detect/virt.sh` → `VIRT=none` (real hardware)

### 5. `detect/battery.sh`
- Battery without installing anything? Look at `/sys/class/power_supply/`.
  Hint: `compgen -G "/sys/class/power_supply/BAT*"`.
- ✓ `bash detect/battery.sh` → `HAS_BATTERY=yes`

### 6. `detect/bluetooth.sh`
- Same trick: `/sys/class/bluetooth/hci*`.
- ✓ `bash detect/bluetooth.sh` → `HAS_BLUETOOTH=yes`

### 7. `detect/net.sh`
- Wi-Fi? An interface with a `wireless` subfolder inside `/sys/class/net/*`.
- Internet? `ping -c1 -W2 1.1.1.1`.
- Prints `NET_WIFI` and `NET_ONLINE`.
- ✓ `bash detect/net.sh` → both `yes` (you're connected)

### 8. `detect/audio.sh`
- `lspci | grep -qi audio`. If `lspci` doesn't exist → `HAS_AUDIO=no`.
- ✓ `bash detect/audio.sh` → `HAS_AUDIO=yes`

### 9. `detect/disk.sh` — the most complete
- With `lsblk`:
  - `lsblk -d -n -o NAME,TYPE` → the first physical disk (row with `TYPE=disk`)
  - `TRAN` → `nvme` / `sata` / `usb`
  - `ROTA` → `0` = SSD, `1` = HDD
  - `-b` + `SIZE` → size in bytes (divide to convert to GB)
- Prints `DISK_NAME`, `DISK_TYPE`, `DISK_SIZE_GB`, `DISK_ROTATIONAL`.
- ✓ `bash detect/disk.sh` →
  `DISK_NAME=nvme0n1`, `DISK_TYPE=nvme`, `DISK_SIZE_GB=238`, `DISK_ROTATIONAL=0`

### 10. `detect/gpu.sh`
- `lspci | grep -Ei 'vga|3d controller|display controller'`:
  `NVIDIA` → nvidia, `Advanced Micro Devices|AMD` → amd, `Intel` → intel.
- ✓ `bash detect/gpu.sh` → `GPU_VENDOR=amd`

---

## Phase 2 — lib/

### 11. `lib/common.sh`
- Shared functions (loaded with `source`, not run on their own):
  - `log` (green), `info` (blue), `warn` (yellow), `error` (red)
  - `have <cmd>` → true if the command exists
- Challenge: colors only activate if the output is a terminal.
  Hint: `[[ -t 1 ]]`. Otherwise print plain text.
- ✓ Create a temporary `prueba.sh` with `source lib/common.sh` + `log "hola"`
  and check it prints in green.

### 12. `lib/api.sh`
- `search_pkg <q>` → `curl -s --fail --max-time 15
  "https://archlinux.org/packages/search/json/?q=$q"`. Investigate why
  `--fail` and `--max-time` matter.
- `pkg_exists <pkg>` → looks for `"pkgname": "<pkg>"` in the response with
  `grep -qE`. Returns: 0 = exists, 1 = doesn't exist, 2 = network failure.
- ⚠️ **Real trap**: the API returns `"pkgname": "x"` (space after the colon).
  A naive grep `"pkgname":"x"` always fails — it happened to me. You need
  `[[:space:]]*` between the colon and the quote.
- ✓ In a terminal: `source lib/api.sh`; `pkg_exists hyprland; echo $?` → 0;
  `pkg_exists nonexistent-package-xyz; echo $?` → 1.

---

## Phase 3 — main.sh (orchestrator)

> `#!/usr/bin/env bash`, `set -uo pipefail`. Structure: `usage()` + one
> function per subcommand + `case "$1"` that dispatches.

### 13. `detect` subcommand
- `for` over `detect/*.sh`, run each with `bash`, dump everything to
  `output/facts.txt`, then `sort`.
- ✓ `./main.sh detect` → prints the table and `cat output/facts.txt` has 14
  `KEY=VALUE` lines.

### 14. `decide` subcommand
- `source output/facts.txt` (loads the variables), `source decide/packages.sh`,
  call the tree function.
- Writes `output/packages.txt`: one package per line, sorted.
- ✓ `./main.sh decide` → and `wc -l output/packages.txt` ≥ 30.

### 15. Generate `output/report.md`
- Markdown with: detected facts table + package list with its reason. You
  need to iterate two parallel arrays by index (`${!arr[@]}`).
- ✓ `./main.sh decide` → open the report, each package has its why.

### 16. `search` and `check` subcommands
- `search <q>`: calls `search_pkg` and shows name / repo / version.
- `check`: iterates `packages.txt` with `pkg_exists`, counts ✓ and ✗; if
  there are ✗, suggest AUR. Returns exit code ≠ 0 if something fails
  (how? `return 1`).
- ✓ `./main.sh search hyprland` → results with repo and version.
  `./main.sh check` → "All packages exist" (33 packages, 0 failures).

---

## Phase 4 — decide/packages.sh (the heart)

### 17. The decision tree
- Two parallel arrays: `PACKAGES` and `REASONS`. `add <pkg> <reason>`
  function. Optional: `add_group <name> <pkg...>` for groups with a common
  reason.
- Minimum rules your machine must trigger:
  - `CPU_VENDOR=amd` → `amd-ucode` (intel → `intel-ucode`)
  - `GPU_VENDOR=amd` → `mesa` + `vulkan-radeon`
  - `HAS_BLUETOOTH=yes` → `bluez` + `bluez-utils`
  - `HAS_BATTERY=yes` → `brightnessctl` + `tlp`
  - Base: `base base-devel linux git vim networkmanager sudo`
  - Hyprland: `hyprland hyprpaper hyprlock hypridle waybar wofi kitty grim
    slurp wl-clipboard xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    polkit-kde-agent ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji`
  - Audio: `pipewire pipewire-pulse wireplumber`
- Challenge 1: deduplicate (a package can come from several rules).
  Investigate associative arrays: `declare -A`.
- Challenge 2: **don't add `libva-mesa-driver`** — it no longer exists as a
  package (it was merged into `mesa` in 2024). If you try, the `check` will
  tell you. 😉
- Challenge 3: if `VIRT` is not `none`, don't install specific GPU drivers
  (a VM doesn't need them) — only `mesa`.
- ✓ `./main.sh check` → 0 failures.

---

## Phase 5 — Final meta

- [ ] `./main.sh all` ends with *"All packages exist in the official repos"*
  and exit code 0.
- [ ] You should be able to explain out loud: why AMD → amd-ucode? why
  doesn't a VM carry GPU drivers? why pipewire and not pulseaudio?
- [ ] Test it from scratch: `./main.sh clean && ./main.sh all`.
- [ ] Make the final commit and, when you want, `git push` to your repo
  (`git@github.com:cleivaj/cleiva_arch.git`).

---

## After (long roadmap)

1. **Partitioning**: use `FIRMWARE` (uefi/bios), `DISK_*` and `RAM_GB` to
   generate the partition table (EFI + root, swap size).
2. **Real installation**: `pacstrap`, `arch-chroot`, `mkinitcpio`, bootloader.
   Test it in QEMU, never on your machine.
3. **Profiles**: GNOME/KDE/i3 besides Hyprland; dev/gaming profiles.
4. **Fine GPU**: choose `nvidia` vs `nvidia-open` by reading the PCI device
   ID (`lspci -nn`).
