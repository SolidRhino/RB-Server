{
  inputs = {
    stable.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    small.url = "github:nixos/nixpkgs/nixos-unstable-small";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    argononed = {
      url = "gitlab:DarkElvenAngel/argononed";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, sops-nix, argononed, ... }: {
    images = {
      server = (self.nixosConfigurations.server.extendModules {
        modules = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];
      }).config.system.build.sdImage;
    };

    nixosConfigurations = {
      server = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit argononed; };
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./configuration.nix
          ./base.nix
          ./argononed.nix
          sops-nix.nixosModules.sops
        ];
      };
    };
  };
}
