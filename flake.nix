{
  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    #nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, sops-nix, ... }: {

    nixosModules.openFirewall = { config, pkgs, lib, ... }: {
      services.openssh.openFirewall = lib.mkForce true;
    };

    images = {
      server = (self.nixosConfigurations.server.extendModules {
        modules = [
          self.nixosModules.openFirewall
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ];
      }).config.system.build.sdImage;
    };

    nixosConfigurations = {
      server = nixpkgs.lib.nixosSystem {
        #specialArgs = { inherit argononed; };
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./configuration.nix
          ./base.nix
          sops-nix.nixosModules.sops
        ];
      };
    };
  };
}
