# Edit this configuration file to define what should be installed on
# your system.    Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix <home-manager/nixos> ];

  # I got bored of nixos at around this time
  home-manager = {
    useGlobalPkgs = true;
    users.vlk = { pkgs, ... }: {
    home = {
      username = "vlk";
      pointerCursor = {
        name = "GoogleDot-Red";
        size = 24;
        package = pkgs.google-cursor;
        gtk.enable = true;
        x11.enable = true;
      };
      sessionVariables = {
        CARGO_HOME = "$HOME/.local/share/cargo";
        RUSTUP_HOME = "$HOME/.local/share/rustup";
      };
      shellAliases = {
        ls = "\\eza -AX --group-directories-first --icons=always";
        sl = "\\eza -AX --group-directories-first --icons=always";
        l = "\\eza -AX --group-directories-first --icons=always";
        ll = "\\eza -AXlhM --git --group-directories-first --icons=always";
        q = "\\exit";
      };
      sessionPath = [
        "$HOME/bin"
#         "${home.config.sessionVariables.CARGO_HOME}/bin"
      ];
      stateVersion = "24.05";
#       programs = {
#         eza.enable = true;
#
#       firefox = {
#         enable = true;
#         package = pkgs.firefox-devedition-bin;
#         profiles = {
#           coding = {
#             id = 1;
#             isDefault = true;
#             bookmarks = [
#               {
#                 name = "nixpkg";
#                 url = "https://search.nixos.org/packages";
#               }
#               {
#                 name = "nixman";
#                 url = "https://nixos.org/manual/nix/unstable";
#               }
#               {
#                 name = "all config keys";
#                 url = "https://nixos.org/manual/nixos/unstable/options.html";
#               }
#             ];
#             search = {
#               default = "DuckDuckGo";
#               force = true;
#             };
#             settings = {
#               "devtools.everOpened" = true;
#               "extensions.formautofill.addresses.enabled" = false;
#               "extensions.formautofill.creditCards.enabled" = false;
#               "font.name.monospace.x-western" = "monospace";
#               "font.name.sans-serif.x-western" = "sans-serif";
#               "font.name.serif.x-western" = "serif";
#               "media.videocontrols.picture-in-picture.video-toggle.has-used" = true;
#               "network.dns.disablePrefetch" = true;
#               "network.predictor.enabled" = false;
#               "network.prefetch-next" = false;
#               "privacy.annotate_channels.strict_list.enabled" = true;
#               "privacy.fingerprintingProtection" = true;
#               "privacy.globalprivacycontrol.was_ever_enabled" = true;
#               "trailhead.firstrun.didSeeAboutWelcome" = true;
#               "browser.aboutConfig.showWarning" = false;
#             };
#           };
#         };
#       };
#       };
    };
    };
  };

  services = {
    xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "";
      videoDrivers = [ "nvidia" ];
      excludePackages = [ pkgs.xterm ];
      displayManager = {
        defaultSession = "plasmawayland";
        sddm = {
          enable = true;
          autoNumlock = true;
          wayland = { enable = true; };
        };
      };
      desktopManager = {
        plasma5 = {
          enable = true;
          phononBackend = "vlc";
        };
      };
    };
    printing.enable = false;
    supergfxd.enable = true;
    switcherooControl.enable = true;
    power-profiles-daemon.enable = true;
    asusd = {
      enable = true;
      enableUserService = true;
    };
    nextdns.enable = true;
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
  };
  environment = {
    localBinInPath = true;
    shellAliases = {
      #ls = "command ls -A --color=auto --group-directories-first";
      ls = "command eza -AX --group-directories-first --icons=always";
      sl = "command eza -AX --group-directories-first --icons=always";
      l = "command eza -AX --group-directories-first --icons=always";
      ll = "command eza -AXlhM --git --group-directories-first --icons=always";
      q = "exit";
    };
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man\\!";
    };
    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_BIN_HOME = "$HOME/.local/bin";
      SUDO_PROMPT = "yo what ur password dawg > ";
      #NIXOS_OZONE_WL = "1";
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "GoogleDot-Red";
    };
    plasma5 = { excludePackages = with pkgs; [ plasma5Packages.oxygen ]; };
    systemPackages = with pkgs; [
      brave
      librewolf
      junction

      discord
      bitwarden
      vscodium-fhs

      cargo-flamegraph

      perl538Packages.PLS
      perl538Packages.PerlTidy
      nodePackages_latest.bash-language-server
      nodePackages_latest.pyright
      shellcheck
      shfmt
      typescript
      nixfmt
      rustup
      nodejs_21

      neofetch
      fastfetch

      jq
      yq
      xsv

      atuin
      starship
      zoxide
      any-nix-shell
      zsh-completions
      zsh-fast-syntax-highlighting
      nix-zsh-completions
      zsh-autocomplete
      zsh-powerlevel10k
      zsh-abbr
      zsh-vi-mode
      zsh-defer

      chafa
      exiftool
      lscolors
      trash-cli

      pandoc
      glow
      csvkit
      poppler_utils
      gh
      git-extras
      delta
      bat
      fortune
      clolcat
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

      btop
      ranger
      difftastic
      bandwhich
      xplr

      grim
      slurp
      swappy
      satty
      wl-clipboard

      kooha
      gimp-with-plugins
      obs-studio
      vlc
      openai-whisper
      v4l-utils

      kdiskmark
      libsForQt5.ghostwriter
      libsForQt5.yakuake

      libsForQt5.polonium
      libsForQt5.plasmatube
      libsForQt5.filelight
      libsForQt5.kdenlive
      partition-manager
      kate

      space-cadet-pinball
      snes9x-gtk
      libsForQt5.kbreakout

      prismlauncher-unwrapped
      temurin-jre-bin-8
      #temurin-jre-bin-17
      temurin-bin-21

      rofi-wayland
      rofimoji

      waycheck
      xwaylandvideobridge
      xorg.xeyes

      adw-gtk3
      lightly-qt
      gradience
      google-cursor

      libreoffice-qt

      mangohud
      protonup-qt

      linuxKernel.packages.linux_xanmod_latest.v4l2loopback

      # for Klassy decorations
      cmake
      clang
      libgcc
      gnumake
      extra-cmake-modules
      gettext
      libsForQt5.kdecoration
      libsForQt5.qt5.qtbase
      libsForQt5.qt5.qtdeclarative
      libsForQt5.qt5.qtx11extras
      libsForQt5.qt5.qtwayland
      libsForQt5.kguiaddons
      libsForQt5.kconfig
      libsForQt5.kconfigwidgets
      libsForQt5.kcoreaddons
      libsForQt5.kiconthemes
      libsForQt5.kcmutils
      libsForQt5.kirigami2
      libsForQt5.kirigami-addons
    ];
  };
  programs = {
    dconf.enable = true;
    hyprland.enable = true;
    i3lock = {
      enable = true;
      package = pkgs.i3lock-color;
    };
    steam.enable = true;
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
      #defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
#     home-manager.enable = true;
    zsh = {
      enable = true;
      # for zsh-autocomplete
      enableCompletion = false;
      vteIntegration = false;
      histFile = "$HOME/.local/state/zshist";
      histSize = 5000;
      autosuggestions = {
        enable = true;
        async = true;
        strategy = [ "history" "completion" ];
      };
      setOptions = [
        "auto_cd"
        "multios"
        "no_bg_nice"
        "cdable_vars"
        "extended_glob"
        "glob_dots"
        "glob_complete"
        "complete_in_word"
        "complete_aliases"
        "correct"
        "interactive_comments"
        "prompt_subst"
        "auto_pushd"
        "pushd_ignore_dups"
        "hist_ignore_all_dups"
        "hist_expire_dups_first"
        "hist_reduce_blanks"
        "hist_ignore_space"
        "hist_fcntl_lock"
        "extended_history"
      ];
      syntaxHighlighting.enable = false;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox-bin;
    };
    xwayland = { enable = true; };
    kdeconnect.enable = true;
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
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 3d";
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
    kernel = { sysctl = { "vm.max_map_count" = 2147483647; }; };
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };
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
  sound = { enable = true; };
  security = { rtkit.enable = true; };
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
  nixpkgs = { config = { allowUnfree = true; }; };
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
      powerOnBoot = true;
    };
    pulseaudio.enable = false;
    xone.enable = true;
    cpu.intel = { updateMicrocode = true; };
  };
  fileSystems."/bruh" = {
    device = "/dev/disk/by-uuid/2af5d44b-5f32-4ffb-85ed-c6f45998693d";
    fsType = "ext4";
  };

  # troubleshooting
  #boot.initrd.kernelModules = [ "nvidia" ];
  #boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  #services.usbmuxd.enable = true;
  #services.usbmuxd.package = pkgs.usbmuxd2;

  # Flatpak, if I ever need it
  # services.flatpak.enable = true;
  # flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  #environment.sessionVariables.NIXOS_OZONE_WL = "1";
  #environment.variables = {
  #    EDITOR = "nvim";
  #    VISUAL = "nvim";
  #};
  # Packages required to build Klassy theme:
  # nix-shell -p cmake extra-cmake-modules libsForQt5.kdecoration libsForQt5.qt5.qtdeclarative libsForQt5.qt5.qtx11extras libsForQt5.kguiaddons libsForQt5.kconfig libsForQt5.kconfigwidgets libsForQt5.kcoreaddons gettext libsForQt5.kiconthemes libsForQt5.kcmutils libsForQt5.kirigami2

  # Apparently this is the more correct way to do this

  # programs.hyprland.enable = true;
  # # This autostarts it in the plasma wayland session
  # #programs.waybar.enable = true;

  # #programs.wayfire.enable = true;

  # programs.i3lock = {
  #     enable = true;
  #     package = pkgs.i3lock-color;
  # };

  # programs.steam.enable = true;
  # programs.gamemode.enable = true;
  # programs.gamemode.enableRenice = true;
  # programs.gamescope.enable = true;

  # #programs.tmux.enable = true;

  # programs.git.enable = true;
  # programs.git.package = pkgs.gitFull;

  # #programs.bash.blesh.enable = true;

  # #programs.neovim.enable = true;
  # programs.neovim = {
  #     enable = true;
  #     defaultEditor = true;
  #     viAlias = true;
  #     vimAlias = true;
  # };
  # programs.nix-index = {
  #     enable = true;
  # };

  #programs.virt-manager.enable = true;

  #programs.nm-applet = {
  #enable = true;
  #indicator = true;
  #};

  #programs.dconf.enable = true;

  # programs.xwayland.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #     enable = true;
  #     enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
