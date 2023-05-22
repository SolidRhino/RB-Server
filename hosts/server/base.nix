{ pkgs, lib, ... }:
{
  boot = {
    # Use mainline kernel, vendor kernel has some issues compiling due to
    # missing modules that shouldn't even be in the closure.
    # https://github.com/NixOS/nixpkgs/issues/111683
    kernelPackages = pkgs.linuxPackages_latest;
    # Disable ZFS by not including it in the list(s). Just adds a lot of
    # unnecessary compile time for this simple example project.
    blacklistedKernelModules = lib.mkForce [ "bluetooth" "btusb" "zfs" ];
    #kernelModules = lib.mkForce [ "bridge" "macvlan" "tap" "tun" "loop" "atkbd" "ctr" ];
    supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" "ext4" "vfat" ];
    cleanTmpDir = true;
  };

  # Disable documentation
  documentation.man.enable = false;
  documentation.doc.enable = false;

  # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" usually
  # contains this, it's the one thing from the installer image that we
  # actually need.
  fileSystems."/" =
    {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

  system.stateVersion = "22.11";

  system.activationScripts.report-changes = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.nvd pkgs.nix ]}
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
  '';
}
