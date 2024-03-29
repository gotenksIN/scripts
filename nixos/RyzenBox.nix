# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Allow installing proprietary packages
  nixpkgs.config = { allowUnfree = true; };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest mainline kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "RyzenBox"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Disable service for faster boot times
  systemd.services.NetworkManager-wait-online.enable = false;
  networking.dhcpcd.enable = false;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set GUI specific configs
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    desktopManager = { cinnamon.enable = true; };
    displayManager.defaultSession = "cinnamon";
    videoDrivers = [ "nvidia" ];
  };
  hardware.opengl.enable = true;

  # Set pipewire configuration
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    aria2
    bash
    cmake
    curl
    evince
    ffmpeg
    git
    gnome.eog
    gnome.gnome-screenshot
    htop
    htop
    lsb-release
    nano
    ncdu
    neofetch
    networkmanager
    python310
    python310Packages.pip
    unzip
    wget
  ];

  # Install udev packages
  services.udev.packages = with pkgs; [ android-udev-rules ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.gotenks = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
    ]; # Enable ‘sudo’ and allow use of 'networkmanager' for the user.
  };

  # Configure fonts
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      inter
      jetbrains-mono
      meslo-lgs-nf
      noto-fonts
      noto-fonts-emoji
      open-sans
      roboto
      ubuntu_font_family
    ];
    fontDir.enable = true;
  };

  # Install some packages I use quite often
  users.users.gotenks.packages = with pkgs; [
    bat
    bottom
    capitaine-cursors
    figlet
    fortune
    microsoft-edge-dev
    nixfmt
    ookla-speedtest
    papirus-icon-theme
    plata-theme
    ripgrep
    tdesktop
    vlc
    vscode-with-extensions
    gitRepo
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
