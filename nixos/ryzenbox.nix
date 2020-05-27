{ config, pkgs, ... }:

# Fetch the latest copy of the nixos-unstable channel from my github.
# Inlcudes patch for nvidia drivers to work on latest testing kernel
let unstableTarball = fetchTarball https://github.com/gotenksIN/nixpkgs/archive/nixos-unstable.tar.gz;

in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest testing kernel
    boot.kernelPackages = pkgs.unstable.linuxPackages_testing;

    networking.hostName = "RyzenBox"; # Define your hostname.
  
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

  # Enables wireless support via wpa_supplicant.
  # networking.wireless.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
    networking.firewall.enable = true;

  # Select internationalisation properties.
    i18n.defaultLocale = "en_GB.UTF-8";
    console = {
        font = "Lat2-Terminus16";
        keyMap = "us";
    };

  # Set your time zone.
    time.timeZone = "Asia/Kolkata";

  # List packages installed in system profile. To search, run:
    environment.systemPackages = with pkgs; [
      bash
      wget
    ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
  #   enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
   sound.enable = true;
   hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
   services.xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome3.enable = true;
        videoDrivers = [ "pkgs.unstable.nvidia" ];
        layout = "us";
        };

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

    # Enable extra services for Gnome
    services = {
      gvfs.enable = true;
      udev.packages = with pkgs; [ gnome3.gnome-settings-daemon ];
      gnome3.chrome-gnome-shell.enable = true;
    };

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
      aria2
      bat
      chrome-gnome-shell
      cmake
      cmatrix
      curl
      figlet
      fontconfig
      fortune
      git
      google-chrome-beta
      gnome3.gnome-shell-extensions
      gnome3.gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-dock
      gnumake
      htop
      ncdu
      neofetch
      networkmanager
      noto-fonts
      noto-fonts-emoji
      open-sans
      papirus-icon-theme
      pfetch
      plata-theme
      python38
      python38Packages.python-fontconfig
      tdesktop
      vscode
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?
}
