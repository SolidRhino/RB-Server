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

  outputs = { nixpkgs, self, ... } @ inputs: {

    nixosModules = import ./modules/nixos;

    images = {
      server = (self.nixosConfigurations.server.extendModules {
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ];
      }).config.system.build.sdImage;
    };

    nixosConfigurations = {
      server = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = inputs;
        modules = [
          ./hosts/server
        ];
      };
    };
  };
}
