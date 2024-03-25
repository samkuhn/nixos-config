{ config
, pkgs
, lib
, inputs
, ...
}: {
  # Allow opening a shell during boot.
  # systemd.additionalUpstreamSystemUnits = ["debug-shell.service"];

  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  suites.single-user.enable = true;
  #suites.sway.enable = true;

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #boot.plymouth.enable = true;
  #boot.consoleLogLevel = 3;
  #boot.kernelParams = [ "quiet" "udev.log_priority=3" ];
  #boot.loader.timeout = 0;

  boot = {
    kernelParams = [
      "verbose=1"
      "boot.trace=1"
      "boot.shell_on_fail=1"
      "boot.debug1=1"          # stop right away
      "boot.debug1device=1"    # stop after loading modules and creating device nodes
      "boot.debug1mounts=1"    # stop after mounting file systems
    ];
  };

  programs.nix-ld.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Smartcard daemon for Yubikey
  #services.pcscd.enable = true;

  security.sudo.enable = true;

  # On my desktop I don't want to run into file limitations.
  # Using vite with a large project made Chromium reach the
  # limit, resulting in weird behaviour without proper errors. Never again.
  #security.pam.loginLimits = [
  #  {
  #    domain = "*";
  #    type = "soft";
  #    item = "nofile";
  #    value = "-1";
  #  }
  #  {
  #    domain = "*";
  #    type = "hard";
  #    item = "nofile";
  #    value = "-1";
  #  }
  #];

  hardware.bluetooth = {
    enable = true;
    #hsphfpd.enable = true;
    settings = {
      General = {
        # To enable BlueZ Battery Provider
        Experimental = true;
      };
    };
  };

  #hardware.logitech.wireless = {
  #  enable = true;
  #  enableGraphical = true;
  #};

  # Workaround: https://github.com/NixOS/nixpkgs/issues/114222
  #systemd.user.services.telephony_client.enable = false;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  /*
  # SK Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"]; # or "nvidiaLegacy470 etc.

  # SK nvidia driver
  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # SK nvidia prime
  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    #sync.enable = true;
    # Make sure to use the correct Bus ID values for your system!
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
  */

  networking = {
    hostName = "rogstrixg1660ti";

    firewall = {
      enable = true;
      allowedTCPPorts = [
        3000 # Development
        8080 # Development
      ];
      allowPing = true;
    };

    networkmanager = {
      enable = true;
      plugins = with pkgs; [ networkmanager-openvpn ];
    };
  };

  networking.wireless.idw.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  fonts = {
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "SauceCodePro Nerd Font"
        ];
      };
    };
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
      corefonts # Microsoft free fonts
      noto-fonts
      noto-fonts-emoji
    ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  #services.xserver.displayManager.autoLogin.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "gb";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    bash
    moreutils # sponge...
    unzip
    vim
    wget
    htop
    efibootmgr

    # Networking tools
    inetutils # hostname ping ifconfig...
    dnsutils # dig nslookup...
    bridge-utils # brctl
    iw
    wirelesstools # iwconfig

    # docker

    usbutils # lsusb

    #polkit_gnome

    sbctl

    neovim 
    #lunarvim
    #tmux 
    wget
    git
    #nodejs
    #yarn
    google-chrome
    python3
    htop
    btop
    nvtop
    glmark2
    inkscape-with-extensions
    pinta
    lshw
    #direnv
    #vscode
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions;
        [
          bbenoist.nix
          ms-python.python
          ms-azuretools.vscode-docker
          ms-vscode-remote.remote-ssh
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          #{
          #  name = "Supermaven";
          #  publisher = "Supermaven";
          #  version = "0.1.19";
          #  sha256 = "7e7f5c54f7d15c8b9bc7b2029d0135ba1de2adb0cf273f65c08dadc6b8a0eea0";
          #}
          {
            name = "cody-ai";
            publisher = "sourcegraph";
            version = "1.9.1710429091";
            sha256 = "eaa298a4d63bd018b049fb0b340053778d1a97c3639b277f179400a9e8bc2574";
          }
          #{
          #  name = "gpt-pilot-vs-code";
          #  publisher = "PythagoraTechnologies";
          #  version = "0.1.5";
          #  sha256 = "8565e0f40735a16c5930409242ec100ea549038496db57836cb2fb6d8efb97cb";
          #}
        ];
    })
  ];

  # Use experimental nsncd. See https://flokli.de/posts/2022-11-18-nsncd/
  #services.nscd.enableNsncd = true;

  services.acpid.enable = true;
  security.polkit.enable = true;
  services.upower = {
    enable = true;
    timeAction = 5 * 60;
    criticalPowerAction = "Hibernate";
  };
  #services.tlp.enable = true;
  services.earlyoom.enable = true;

  # Set permissions for RTL2832 USB dongle to use with urh.
  #hardware.rtl-sdr.enable = true;

  #services.udev.extraRules = ''
    # Thunderbolt
    # Always authorize thunderbolt connections when they are plugged in.
    # This is to make sure the USB hub of Thunderbolt is working.
    #ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"

    # Saleae Logic Analyzer
    #SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0925", ATTR{idProduct}=="3881", MODE="0666"
    #SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="21a9", ATTR{idProduct}=="1001", MODE="0666"

    # Arduino
    #SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="2341", ATTR{idProduct}=="0043", MODE="0666", SYMLINK+="arduino"
    #SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", MODE="0664", GROUP="uucp"
    #SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", MODE="0660", SYMLINK+="ttyArduinoUno"
    #SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0660", SYMLINK+="ttyArduinoNano2"
    #SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0660", SYMLINK+="ttyArduinoNano"

    # For OVR
    #KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2833", TAG+="uaccess"

    # For OpenHMD
    #SUBSYSTEM=="usb", ATTRS{idVendor}=="2833", TAG+="uaccess"
  #'';

  services.locate = {
    enable = true;
    pruneNames = [ ];
  };
  services.openssh.enable = false;

   services.printing = {
     enable = true;
     drivers = with pkgs; [ gutenprint splix cups-bjnp ];
   };

  #services.avahi = {
  #  enable = true;
  #  browseDomains = [ ];

    # Seems to be causing trouble/slowness when resolving hosts
    #nssmdns = true;

  #  publish.enable = false;
  #};

  services.redshift.enable = true;
  location.provider = "geoclue2";

  #services.greetd = {
  #  enable = true;
  #  settings = {
  ##    default_session = {
  #      command = "${lib.getExe pkgs.cage} ${lib.getExe pkgs.greetd.gtkgreet}";
  #    };
  ##    initial_session = {
  #      command = "${lib.getExe pkgs.sway}";
  ##      user = config.suites.single-user.user;
  #    };
  #  };
  #};

  # Fingerprint reader
  #services.fprintd.enable = true;
  #security.pam.services.login.fprintAuth = true;
  #security.pam.services.xscreensaver.fprintAuth = true;

  #services.gnome.gnome-keyring.enable = true;

  #i18n.inputMethod = {
  #  enabled = "ibus";
  #  ibus.engines = with pkgs.ibus-engines; [ uniemoji typing-booster ];
  #};

  #programs.fish.enable = true;
  #programs.bash.enableCompletion = true;
  programs.tmux.enable = true;
  #programs.adb.enable = true;

  #programs._1password.enable = true;
  #programs._1password-gui = {
  #  enable = true;
  #  polkitPolicyOwners = [ config.suites.single-user.user ];
  #};

  # virtualisation.virtualbox.host.enable = true;
  #virtualisation.docker = {
  #  enable = true;
    # daemon.settings = {
    #   ipv6 = true;
    #   "fixed-cidr-v6" = "fd00::/80";
    # };
  #  autoPrune.enable = true;
  #};
  #networking.firewall.trustedInterfaces = [ "docker0" ];

  #users.defaultUserShell = pkgs.fish;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
  ];

  #documentation.enable = false;
  #documentation.nixos.enable = false;

  home-manager.sharedModules = [{
    programs.git.signing.key = "2BA975040411E0DE97B44224D0C37FC5C11D1D60";
  }];

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;

    gc = {
      dates = "weekly";
      automatic = true;
      options = "--delete-older-than 60d";
    };

    settings = {
      #sandbox = true;
      #extra-sandbox-paths = [ "/etc/nix/netrc" ];
      trusted-users = [ "root" "${config.suites.single-user.user}" ];
      #substituters = [ "https://cachix.cachix.org" ];
      extra-experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
      #netrc-file = "/etc/nix/netrc";
      #auto-optimise-store = true;
      #log-lines = 100;
      #warn-dirty = false;
    };
    package = pkgs.nixVersions.unstable;
  };

  #system.autoUpgrade = {
  #  enable = false;
  #  flake = "/home/bob.vanderlinden/projects/bobvanderlinden/nixos-config";
  #  flags = [ "--update-input" "nixpkgs" "--commit-lock-file" ];
  #  dates = "17:30";
  #};

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
