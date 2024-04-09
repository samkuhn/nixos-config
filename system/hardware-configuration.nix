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
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "kvm-intel" "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "thunderbolt" "rtsx_pci_sdmmc" "dm-snapshot" "kvm-intel" "i915" ];
  # boot.initrd.kernelModules = [ "dm-snapshot" ];
  # https://wiki.archlinux.org/index.php/Kernel_mode_setting#Early_KMS_start
  # Enable framebuffer compression (FBC)
  # can reduce power consumption while reducing memory bandwidth needed for screen refreshes.
  # https://wiki.archlinux.org/index.php/intel_graphics#Framebuffer_compression_(enable_fbc)
  #boot.kernelParams = [ "i915.enable_fbc=1" ];
  #boot.extraModulePackages = [ ];

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # Disable systemd-boot, as it is replaced by lanzaboote.
  # boot.loader.systemd-boot.enable = true;
  #boot.loader.systemd-boot.netbootxyz.enable = true;
  
  # Secure boot
  #boot.loader.systemd-boot.enable = false;
  #boot.lanzaboote.enable = false; 
  #boot.lanzaboote.pkiBundle = "/mnt/etc/secureboot";

  #boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";
  #boot.loader.efi.efiSysMountPoint = "/mnt/boot/EFI";

  #boot.initrd.luks.devices.luksroot = {
  #  device = "/dev/disk/by-uuid/c183b9d6-3f8c-4f02-87ae-873e428e467f";
  #  allowDiscards = true;
  #  preLVM = true;
  #};

  # random internet
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.grub.useOSProber = true;
  #boot.supportedFilesystems = [ "xfs" "ext4" "nfs4" "fuse" ];
  #boot.tmpOnTmpfs = true;

  # lo config
  #boot.initrd.luks.devices.lo = {
  #  device = "/dev/sda3";  
  #  preLVM = true;
  #  allowDiscards = true;
  #  name = "lo";
  #  #keyFile = "/path/to/your/keyfile"; # Optional
  #};

  # ld config
  #boot.initrd.luks.devices.ld = {
  #  device = "/dev/sda4";  
  #  preLVM = true;
  #  allowDiscards = true;
  #  name = "ld";
  #  #keyFile = "/path/to/your/keyfile"; # Optional
  #};

  # do config
  boot.initrd.luks.devices.do = {
    device = "/dev/sda5";  
    preLVM = true;
    allowDiscards = true;
    name = "do";
    #keyFile = "/path/to/your/keyfile"; # Optional
  };

  # dd config
  boot.initrd.luks.devices.dd = {
    device = "/dev/sda6";  
    preLVM = true;
    allowDiscards = true;
    name = "dd";
    #keyFile = "/path/to/your/keyfile"; # Optional
  };

  fileSystems."/" = {
    device = "/dev/mapper/lo";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7891-8FAA";
    fsType = "vfat";
  };

  #fileSystems."/boot/efi" = {
  #  device = "/dev/disk/by-uuid/7891-8FAA";
  #  fsType = "vfat";
  #};

  swapDevices = [ ];
  #swapDevices = [
  #  {
  #    device = "/dev/disk/by-uuid/c183b9d6-3f8c-4f02-87ae-873e428e467f";
  #  }
  #];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;
 
  #boot.loader.grub.devices = [ "/dev/disk/by-uuid/7891-8FAA" ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
