{
  description = "My Custom Packages and Modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in {
      # 1. EXPORT OVERLAY
      overlays.default = import ./pkgs/default.nix;

      # 2. EXPORT ALL PACKAGES ACTUALLY IN THIS REPO
      packages = forEachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          grimmory = pkgs.callPackage ./pkgs/grimmory/package.nix { };
          bytestash = pkgs.callPackage ./pkgs/bytestash/package.nix { };
          calibre-web-automated = pkgs.callPackage ./pkgs/calibre-web-automated/package.nix { };
          decky-loader = pkgs.callPackage ./pkgs/decky-loader/default.nix { };
          bibata-hyprcursor = pkgs.callPackage ./pkgs/bibata-hyprcursor/default.nix { };
          it-tools = pkgs.callPackage ./pkgs/it-tools/package.nix { };
          networking-toolbox = pkgs.callPackage ./pkgs/networking-toolbox/package.nix { };
          omni-tools = pkgs.callPackage ./pkgs/omni-tools/package.nix { };
          mazanoke = pkgs.callPackage ./pkgs/mazanoke/package.nix { };
          yamtrack = pkgs.callPackage ./pkgs/yamtrack/default.nix { };
          ab-download-manager = prev.callPackage ./ab-download-manager/package.nix { };
        }
      );

      # 3. EXPORT MODULES (Mapped to actual repo paths)
      nixosModules = {
        default = self.nixosModules.all;
        all = { ... }: {
          imports = [
            ./pkgs/grimmory/module.nix
            ./pkgs/bytestash/module.nix
            ./pkgs/calibre-web-automated/module.nix
            ./pkgs/it-tools/module.nix
          ];
        };
        grimmory = import ./pkgs/grimmory/module.nix;
        bytestash = import ./pkgs/bytestash/module.nix;
        calibre-web-automated = import ./pkgs/calibre-web-automated/module.nix;
        it-tools = import ./pkgs/it-tools/module.nix;
      };
    };
}
