# pkgs/default.nix
final: prev: {
  grimmory = prev.callPackage ./grimmory/package.nix { };
  bytestash = prev.callPackage ./bytestash/package.nix { };
  bookorbit = prev.callPackage ./bookorbit/package.nix { };
  decky-loader = prev.callPackage ./decky-loader/default.nix { };
  bibata-hyprcursor = prev.callPackage ./bibata-hyprcursor/default.nix { };
  it-tools = prev.callPackage ./it-tools/package.nix { };
  networking-toolbox = prev.callPackage ./networking-toolbox/package.nix { };
  omni-tools = prev.callPackage ./omni-tools/package.nix { };
  mazanoke = prev.callPackage ./mazanoke/package.nix { };
  yamtrack = prev.callPackage ./yamtrack/default.nix { };
  yamtrack-git = prev.callPackage ./yamtrack/yamtrack-git.nix { };
  ab-download-manager = prev.callPackage ./ab-download-manager/package.nix { };
  komf = prev.callPackage ./komf/package.nix { };
}
