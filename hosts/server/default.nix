{ sops-nix
, lib
, nixos-hardware
, config
, pkgs
, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    nixos-hardware.nixosModules.raspberry-pi-4
    sops-nix.nixosModules.sops
  ];

  # Disable documentation
  documentation.man.enable = false;
  documentation.doc.enable = false;

  system.stateVersion = "22.11";

  system.activationScripts.report-changes = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.nvd pkgs.nix ]}
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
  '';
}
