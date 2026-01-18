=====
Jan 2026 note: We attempted the dual-OS plan to reclaim space from Windows D by installing a second NixOS (ob) on sda5 as a maintenance OS, then shrinking Windows and resizing oa/da/db from ob. In practice we hit a long chain of boot issues: systemd-boot entries were overwritten, kernels/initrds were mixed across OA/OB, OA booted into a 90s hang/panic, and even a live-USB chroot hit PTY allocation problems. After many rounds of recovery and troubleshooting (manual loader entries, LUKS UUID fixes, etc.), we reverted to the stable branch and parked the dualos branch. The "golden ticket" remains our best-known plan if we attempt this again, but for now we are back on the main line and keeping swap/boot configs conservative.
=====

🟨 NIXOS DUAL-BOOT GOLDEN TICKET (OA + OB, systemd-boot)

Status: battle-tested
Bootloader: systemd-boot
Encryption: LUKS
Goal: two independent NixOS installs that never overwrite each other’s boot entries, with readable boot menu labels.

🧭 Disk layout (example, adjust device names if needed)
Purpose    Device    Notes
EFI System Partition    /dev/nvme0n1p1    vfat
OA root    /dev/sda3    LUKS + ext4
DA data (optional)    /dev/sda4    LUKS + ext4
OB root    /dev/sda5    LUKS + ext4
0️⃣ Preflight (Live USB)
lsblk -f
sudo fdisk -l


Confirm device names before proceeding.

1️⃣ Clean the ESP (do this once)
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot
sudo rm -f /mnt/boot/loader/entries/nixos*.conf
sudo umount /mnt/boot


❌ Do NOT delete:

/EFI/Microsoft

/EFI/systemd

/EFI/BOOT

/loader/loader.conf

2️⃣ REQUIRED CONFIG (prevents entry clobbering)

In your shared system/configuration.nix:

boot.loader.systemd-boot.enable = true;
boot.loader.efi = {
  canTouchEfiVariables = true;
  efiSysMountPoint = "/boot";
};

boot.loader.systemd-boot.extraInstallCommands = ''
  set -euo pipefail
  for entry in /boot/loader/entries/nixos-generation-*.conf; do
	[ -f "$entry" ] || continue
	gen="$(basename "$entry")"
	install -Dm644 "$entry" \
  	"/boot/loader/entries/${config.system.name}-$gen"
  done
'';

WHY THIS MATTERS

systemd-boot deletes nixos*.conf on reinstall

entries named oa-* and ob-* are immune

this makes the process reinstall-safe

3️⃣ Install OA (primary system)
sudo cryptsetup luksFormat /dev/sda3
sudo cryptsetup open /dev/sda3 oa
sudo mkfs.ext4 -L oa /dev/mapper/oa

sudo mkdir -p /mnt/oa /mnt/oa/boot
sudo mount /dev/mapper/oa /mnt/oa
sudo mount /dev/nvme0n1p1 /mnt/oa/boot

sudo nixos-install \
  --root /mnt/oa \
  --flake /mnt/da/nixos-config#rogstrixg1660tia


Verify:

ls /mnt/oa/boot/loader/entries
# expect oa-nixos-generation-*.conf


Unmount OA:

sync
sudo umount /mnt/oa/boot
sudo umount /mnt/oa
sudo cryptsetup close oa

4️⃣ Install OB (secondary system)
sudo cryptsetup luksFormat /dev/sda5
sudo cryptsetup open /dev/sda5 ob
sudo mkfs.ext4 -L ob /dev/mapper/ob

sudo mkdir -p /mnt/ob /mnt/ob/boot
sudo mount /dev/mapper/ob /mnt/ob
sudo mount /dev/nvme0n1p1 /mnt/ob/boot

sudo nixos-install \
  --root /mnt/ob \
  --flake /mnt/da/nixos-config#rogstrixg1660tib


Verify:

ls /mnt/ob/boot/loader/entries
# expect oa-* and ob-* entries

5️⃣ Make boot menu readable (IMPORTANT)
sudo sed -i 's/^title.*/title   NixOS OA/' \
  /mnt/ob/boot/loader/entries/oa-nixos-generation-*.conf

sudo sed -i 's/^title.*/title   NixOS OB/' \
  /mnt/ob/boot/loader/entries/ob-nixos-generation-*.conf


Check:

head -n 5 /mnt/ob/boot/loader/entries/oa-nixos-generation-1.conf
head -n 5 /mnt/ob/boot/loader/entries/ob-nixos-generation-1.conf

6️⃣ Final unmount + reboot
sync
sudo umount /mnt/ob/boot
sudo umount /mnt/ob
sudo cryptsetup close ob

reboot

✅ Expected boot menu

You will see clear entries:

NixOS OA

NixOS OB

Windows Boot Manager (if present)

Each will prompt for its own LUKS passphrase.

🔧 Post-boot notes

Root password failures during install are harmless
Fix later with:

sudo passwd


Future nixos-rebuild or nixos-install:

will not delete the other system

will create new oa-* / ob-* entries safely

🏁 Final verdict

This procedure is now:

✅ deterministic

✅ reinstall-safe

✅ boot-menu-clear

✅ suitable for documentation / README

If you want next:

swapfile setup

shared /home or data mounts

snapshotting

turning this into an INSTALL.md

Just say the word.

--- 

