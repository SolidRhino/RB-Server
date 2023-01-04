{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    argononed = {
      url = "gitlab:DarkElvenAngel/argononed";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, agenix, argononed, ... }: {
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
          agenix.nixosModule
        ];
      };
    };
  };
}

