# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config = {
    allowUnfree = true;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Use the latest testing kernel
    boot.kernelPackages = pkgs.unstable.linuxPackages_testing;

  networking.hostName = "GroundBox"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable NetworkManager
    networking.networkmanager.enable = true;
  
  # Disable service for faster boot times
    systemd.services.NetworkManager-wait-online.enable = false;
    networking.dhcpcd.enable = false;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  # networking.useDHCP = false;
  # networking.interfaces.eno1.useDHCP = false;
  # networking.interfaces.enp0s20f0u1.useDHCP = false;
  # networking.interfaces.wlo1.useDHCP = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
    i18n.defaultLocale = "en_GB.UTF-8";
    console = {
        font = "Lat2-Terminus16";
        keyMap = "us";
    };

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Configure fonts
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs.latest; [
      cascadia-code
      pkgs.custom.jetbrains-mono-nerdfonts
      noto-fonts
      roboto
      ubuntu_font_family
    ];

  # List packages installed in system profile. To search, run:
    environment.systemPackages = with pkgs; [
    busybox
    cmake
    curl
    htop
    lsb-release
    nano
    networkmanager
    ninja
    plata-theme
    python38
    python38Packages.pip
    python38Packages.python-fontconfig
    traceroute
    wget
    unzip
    ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
    };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
    services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
   services.xserver = {
        enable = true;
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
        libinput.enable = true;
        layout = "us";
        };

  # Install udev packages
  services.udev.packages = with pkgs; [
    android-udev-rules
    libu2f-host
    gnome3.gnome-settings-daemon
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.gotenks = {
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [ "wheel" "networkmanager"]; # Enable ‘sudo’ and allow use of 'networkmanager' for the user.
    };

  # Make sure ~/bin is in $PATH.
  environment.homeBinInPath = true;

  # Install some packages I use quite often
    users.users.gotenks.packages = with pkgs; [
      android-udev-rules
      aria2
      bat
      cmatrix
      curl
      figlet
      fontconfig
      fortune
      git
      google-chrome
      gnumake
      htop
      kotatogram-desktop
      ncdu
      neofetch
      networkmanager
      noto-fonts
      noto-fonts-emoji
      open-sans
      papirus-icon-theme
      pfetch
      tdesktop
      vlc
      vscode
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

system.copySystemConfiguration = true;

}

