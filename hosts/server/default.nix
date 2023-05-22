{ sops-nix
, nixos-hardware
, config
, pkgs
, ...
}: {
  imports = [
    ./configuration.nix
    ./base.nix
    nixos-hardware.nixosModules.raspberry-pi-4
    sops-nix.nixosModules.sops
  ];
}
