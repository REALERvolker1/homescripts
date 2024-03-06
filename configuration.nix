# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # I don't think this works
  # systemd = {
  # services = {
  # linkzz = {
  # enable = true;
  # description = "Symlink important interpreters";
  # wantedBy = [ "multi-user.target" ];
  # unitConfig = { type = "simple"; };
  # serviceConfig = {
  # ExecStart = ''
  # sh -c "ln -sfn '$(which bash)' /usr/bin/bash
  # ln -sfn '/usr/bin/bash' /bin/bash
  # ln -sfn '$(which zsh)' /usr/bin/zsh
  # ln -sfn /usr/bin/zsh /bin/zsh
  # ln -sfn '$(which dash)' /usr/bin/dash
  # ln -sfn /usr/bin/dash /bin/dash
  # ln -sfn '$(which perl)' /usr/bin/perl
  # ln -sfn '$(which python3)' /usr/bin/python3"
  # '';
  # };
  # };
  # };
  # };

  environment = {
    localBinInPath = true;
    homeBinInPath = true;
    sessionVariables = rec {
      ZDOTDIR = "$HOME/.config/zsh";

      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_BIN_HOME = "$HOME/.local/bin";

      RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
      CARGO_HOME = "$XDG_DATA_HOME/cargo";
      # RUSTUP_HOME = "$HOME/.local/share/rustup";
      # CARGO_HOME = "$HOME/.local/share/cargo";

      HISTFILE = "$XDG_CACHE_HOME/shellhist";
      # HISTFILE = "$HOME/.cache/shellhist";

      SUDO_PROMPT = "yo what ur password dawg > ";
      #NIXOS_OZONE_WL = "1";
    };
    # to fix the env for my scripts
    # This runs on every shell startup for some reason, and doesn't work anyways
    #extraInit = ''
    #  ln -sfn '$(which bash)' /usr/bin/bash
    #  ln -sfn '/usr/bin/bash' /bin/bash
    #  ln -sfn '$(which zsh)' /usr/bin/zsh
    #  ln -sfn /usr/bin/zsh /bin/zsh
    #  ln -sfn '$(which dash)' /usr/bin/dash
    #  ln -sfn /usr/bin/dash /bin/dash
    #  ln -sfn '$(which perl)' /usr/bin/perl
    #  ln -sfn '$(which python3)' /usr/bin/python3
    #'';
    systemPackages = with pkgs; [
      brave
      junction
      floorp
      # vscode
      vscodium-fhs
      vesktop # build is broken
      jan
      libreoffice-fresh

      perl538Packages.PLS
      perl538Packages.PerlTidy
      nodePackages_latest.bash-language-server
      nodePackages_latest.pyright
      shellcheck
      shfmt
      typescript
      nixfmt
      nixd
      rustup
      nodejs_21
      cmake
      clang
      libgcc
      gnumake
      mold

      neofetch
      fastfetch

      jq
      yq
      xsv

      atuin
      zoxide

      chafa
      exiftool
      lscolors
      trash-cli

      pandoc
      glow
      #csvkit       # requires pandas, that build is broken
      poppler_utils
      gh
      git-extras
      delta
      bat
      tealdeer
      fortune
      clolcat # TODO: Symlink lolcat to clolcat
      libnotify
      inotify-tools

      fzf
      fzy
      yad
      gum
      dash

      wget
      xdg-ninja
      fd
      sysstat
      psmisc
      lsof
      ripgrep
      eza
      ffmpeg
      imagemagick
      graphicsmagick
      killall

      kitty
      alacritty

      btop
      nvtop
      ranger
      difftastic

      grim
      slurp
      swappy
      wl-clipboard
      kitti3

      kooha
      gimp-with-plugins
      obs-studio
      vlc
      mpv
      mpvScripts.mpris
      mpvScripts.cutter
      # openai-whisper
      v4l-utils

      prismlauncher-unwrapped
      temurin-jre-bin-8 # TODO: Figure out if these work for prismlauncher

      rofi-wayland
      rofimoji

      waycheck
      xwaylandvideobridge
      xorg.xeyes

      adw-gtk3
      # gradience
      # google-cursor
      # gnome-browser-connector
      # gnome-extension-manager
      # gnome.gnome-tweaks

      # gnome.gnome-font-viewer
      # gnome.gnome-calculator
      # gnome.file-roller

      # mate.mate-polkit

      # xfce.xfce4-terminal
      # xfce.tumbler
      # xfce.catfish
      # xfce.xfce4-screenshooter # TODO: Remove if this doesn't work on hyprland
      # xfce.ristretto
      # xfce.mousepad

      hyprpaper
      hyprpicker
      hyprlock
      hypridle

      mangohud
    ];
  };

  programs = {
    dconf.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
      ];
    };
    hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    git = {
      enable = true;
      package = pkgs.gitFull;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
    tmux = {
      enable = true;
      # newSession = true;
    };
    zsh = {
      enable = true;
      enableCompletion = false;
      vteIntegration = false;
      syntaxHighlighting.enable = true; # TODO: Change this
    };
    firefox = {
      enable = true;
      package = pkgs.firefox-bin;
    };
    xwayland = { enable = true; };
    virt-manager = { enable = true; };
    nix-ld = {
      enable = true;
      # libraries = with pkgs; [ gtk4-layer-shell libudev-zero libudev0-shim ];
    };
  };

  services = {
    xserver = {
      enable = true;
      autorun = false;
      # They change the syntax on unstable
      xkb = {
        layout = "us";
        variant = "";
        # This might work, idk
        options = "caps:escape";
      };
      # layout = "us";
      # xkbVariant = "";
      videoDrivers = [ "nvidia" ];
      excludePackages = [ pkgs.xterm ];
      displayManager = {
        sddm = {
          enable = true;
          autoNumlock = true;
          wayland = { enable = true; };
        };
      };
      # Temporary, remove later
      desktopManager = {
      plasma5 = {
      enable = true;
      phononBackend = "vlc";
      };
      };
      # libinput = {
        # enable = true;
        # mouse = { accelProfile = "flat"; };
        # touchpad = {
          # accelProfile = "adaptive";
          # disableWhileTyping = true;
          # naturalScrolling = true;
       #   #sendEventsMode = "disabled-on-external-mouse";
          # tapping = true;
        # };
      # };
      windowManager = {
        i3 = {
          enable = true;
          extraPackages = with pkgs; [ i3status i3lock ];
          updateSessionEnvironment = true;
        };
      };
    };
    printing.enable = true;
    blueman.enable = true;
    # gnome.gnome-keyring.enable = true;
    asusd = {
      enable = true;
      enableUserService = true;
    };
    switcherooControl.enable = true;
    power-profiles-daemon.enable = true;
    supergfxd.enable = true;
    # systemd.services.supergfxd.path = [ pkgs.pciutils ];  # might be needed until they fix this
    #nextdns.enable = true;
    earlyoom = {
      enable = true;
      enableNotifications = true;
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
    # picom = {
      # enable = true;
      # TODO: research more into this
    # };
    systemd-lock-handler.enable = true;
    logind = {
      killUserProcesses = true;
      lidSwitch = "suspend";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
      powerKey = "poweroff";
    };
  };
  users = {
    defaultUserShell = pkgs.zsh;
    users = {
      vlk = {
        isNormalUser = true;
        description = "vlk";
        extraGroups = [ "networkmanager" "wheel" ];
        shell = pkgs.zsh;
      };
    };
  };

  systemd = {
    ctrlAltDelUnit = "";
    extraConfig = ''
      DefaultTimeoutStartSec=30s
      DefaultTimeoutStopSec=30s
      DefaultDeviceTimeoutSec=20s
    '';

    user = {
      extraConfig = ''
        DefaultTimeoutStartSec=30s
        DefaultTimeoutStopSec=30s
        DefaultDeviceTimeoutSec=20s
      '';
    };
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      twitter-color-emoji
      nerdfonts
      lato
      fira-code-nerdfont
    ];
    fontconfig = {
      enable = true;
      allowBitmaps = false;
      antialias = true;
      defaultFonts = {
        emoji = [ "Twemoji" ];
        monospace = [ "FiraCode Nerd Font" ];
        sansSerif = [ "Lato" ];
        serif = [ "Tinos Nerd Font" ];
      };
      hinting = {
        enable = true;
        autohint = false;
        style = "slight";
      };
    };
  };

  xdg = {
    # autostart.enable = false;
    # icons.enable = true;
    # menus.enable = true;
    # sounds.enable = true;
    mime = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "evince.desktop";
        "text/xml" = [ "mousepad.desktop" "nvim.desktop" ];
        "image/png" = "ristretto.desktop";
      };
    };
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };
  };

  # qt = {
    # enable = true;
    # platformTheme = "qt5ct";
    # style = "kvantum";
  # };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking = {
    hostName = "iphone";
    networkmanager = { enable = true; };
    firewall = { enable = true; };
  };
  time = { timeZone = "America/Chicago"; };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  sound = {
    enable = true;
    # mediaKeys = {
    # enable = true;
    # volumeStep = 5;
    # };
  };
  security.rtkit.enable = true;

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # virtualisation = {
  # libvirtd = {
  # enable = true;

  zramSwap = {
    enable = true;
    # algorithm = "zstd";
    # memoryMax = 8589934592;     # Hope this is 8gb
    memoryPercent = 25;
    priority = 5;
  };
  boot = {
    #         initrd = {
    #             availableKernelModules = [
    #                 "xhci_pci"
    #                 "thunderbolt"
    #                 "vmd"
    #                 "nvme"
    #                 "usbhid"
    #             ];
    #         };
    kernelModules = [ "nvidia" "v4l2loopback" ];
    #         extraModulePackages = [
    #
    #         ];
    loader = {
      systemd-boot = { enable = true; };
      efi = { canTouchEfiVariables = true; };
    };
    blacklistedKernelModules = [ "nouveau" ];
    kernel = {
      sysctl = {
        "vm.max_map_count" = 2147483647;
        "kernel.split_lock_mitigate" = 0;
      };
    };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver intel-ocl ];
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      dynamicBoost.enable = true;
      forceFullCompositionPipeline = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    pulseaudio.enable = false;
    xone.enable = false;
    cpu.intel = { updateMicrocode = true; };
  };

  fileSystems."/bruh" = {
    device = "/dev/disk/by-uuid/2af5d44b-5f32-4ffb-85ed-c6f45998693d";
    fsType = "ext4";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
