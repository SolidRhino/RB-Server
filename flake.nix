{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = {
    self,
    nixpkgs,
    devenv,
    systems,
    ...
  } @ inputs: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    packages = forEachSystem (system: {
      devenv-up = self.devShells.${system}.default.config.procfileScript;
    });

    nixosModules = import ./modules/nixos;

    images = {
      server =
        (self.nixosConfigurations.server.extendModules {
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ];
        })
        .config
        .system
        .build
        .sdImage;
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
    devShells =
      forEachSystem
      (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            {
              # https://devenv.sh/reference/options/
              delta.enable = true;
              devcontainer = {
                enable = true;
                settings = {
                  customizations.vscode = {
                    settings = {
                      git.alwaysSignOff = true;
                      git.autofetch = true;
                      git.confirmSync = false;
                      nix.enableLanguageServer = true;
                      workbench.colorTheme = "Tokyo Night";
                      workbench.iconTheme = "material-icon-theme";
                    };
                    extensions = [
                      "mkhl.direnv"
                      "signageos.signageos-vscode-sops"
                      "github.vscode-github-actions"
                      "codezombiech.gitignore"
                      "PKief.material-icon-theme"
                      "jnoortheen.nix-ide"
                      "arrterian.nix-env-selector"
                      "enkia.tokyo-night"
                      "kamadorueda.alejandra"
                    ];
                  };
                  updateContentCommand = "";
                };
              };
              languages = {
                nix.enable = true;
              };
              pre-commit = {
                hooks = {
                  pre-commit-hook-ensure-sops.enable = true;
                  detect-aws-credentials.enable = true;
                  detect-private-keys.enable = true;
                  check-yaml.enable = true;
                  editorconfig-checker.enable = true;
                  trim-trailing-whitespace.enable = true;
                  check-added-large-files.enable = true;
                  deadnix.enable = true;
                  alejandra.enable = true;
                  flake-checker.enable = true;
                  check-merge-conflicts.enable = true;
                };
              };
            }
          ];
        };
      });
  };
}
