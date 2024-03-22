# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "thunderbolt" "rtsx_pci_sdmmc" "dm-snapshot" "kvm-intel" "i915" ];
  # boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  # https://wiki.archlinux.org/index.php/Kernel_mode_setting#Early_KMS_start
  boot.initrd.kernelModules = [ "kvm-intel" "i915" ];
  # Enable framebuffer compression (FBC)
  # can reduce power consumption while reducing memory bandwidth needed for screen refreshes.
  # https://wiki.archlinux.org/index.php/intel_graphics#Framebuffer_compression_(enable_fbc)
  boot.kernelParams = [ "i915.enable_fbc=1" ];

  boot.extraModulePackages = [ ];
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # Disable systemd-boot, as it is replaced by lanzaboote.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.netbootxyz.enable = true;
  
  # Secure boot
  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote.enable = true;
  boot.lanzaboote.pkiBundle = "/etc/secureboot";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  #boot.initrd.luks.devices.luksroot = {
  #  device = "/dev/disk/by-uuid/c183b9d6-3f8c-4f02-87ae-873e428e467f";
  #  allowDiscards = true;
  #  preLVM = true;
  #};

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c183b9d6-3f8c-4f02-87ae-873e428e467f";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/c183b9d6-3f8c-4f02-87ae-873e428e467f";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/7891-8FAA";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/c183b9d6-3f8c-4f02-87ae-873e428e467f";
    }
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
