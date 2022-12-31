{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, agenix, ... }: {
    images = {
      server = (self.nixosConfigurations.server.extendModules {
        modules = [ "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];
      }).config.system.build.sdImage;
    };

    nixosConfigurations = {
      server = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./configuration.nix
          ./base.nix
          agenix.nixosModule
        ];
      };
    };
  };
}

