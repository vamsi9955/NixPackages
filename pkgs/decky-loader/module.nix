
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types literalExpression;
  cfg = config.services.decky-loader;

  package = cfg.package.overridePythonAttrs(old: {
    dependencies = old.dependencies ++ (cfg.extraPythonPackages old.passthru.python.pkgs);
  });
in
{
  # ============================================================================
  # MODULE OPTIONS
  # ============================================================================
  
  # FIXED: Pointed the options directly to your custom namespace
  options.services.decky-loader = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the Steam Deck Plugin Loader.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.decky-loader;
      defaultText = literalExpression "pkgs.decky-loader";
      description = ''
        The loader package to use.
      '';
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      example = literalExpression "[ pkgs.curl pkgs.unzip ]";
      default = [];
      description = ''
        Extra packages to add to the service PATH.
      '';
    };

    extraPythonPackages = mkOption {
      type = types.functionTo (types.listOf types.package);
      example = literalExpression "pythonPackages: with pythonPackages; [ hid ]";
      default = _: [];
      defaultText = literalExpression "pythonPackages: []";
      description = ''
        Extra Python packages to add to the PYTHONPATH of the loader.
      '';
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/decky-loader";
      description = ''
        Directory to store plugins and data.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "decky";
      description = ''
        The user Decky Loader should run plugins as.
      '';
    };
    # REQUIRED for Desktop Linux
    steamUser = mkOption {
      type = types.str;
      description = "Your primary Linux username that runs Steam (required for CEF debugging workaround).";
    };
  };

  # ============================================================================
  # MODULE IMPLEMENTATION
  # ============================================================================

  config = mkIf cfg.enable (mkMerge [
    # ADD THIS BLOCK TO WHITELIST PNPM:
    {
      nixpkgs.config.permittedInsecurePackages = [
        "pnpm-9.15.9"
      ];
    }
    # 1. Create the unprivileged user if default is used
    (mkIf (cfg.user == "decky") {
      users.users.decky = {
        group = "decky";
        home = cfg.stateDir;
        isSystemUser = true;
      };
      users.groups.decky = {};
    })
    
    # 2. Systemd Service Definition
    {
      # As of 2023/07/16, the Decky Loader needs to run as root, even if you never
      # use plugins that require it. It setuid's to the unprivileged user to
      # run plugins. Running as non-root is unsupported.
      systemd.services.decky-loader = {
        description = "Steam Deck Plugin Loader";

        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        environment = {
          UNPRIVILEGED_USER = cfg.user;
          UNPRIVILEGED_PATH = cfg.stateDir;
          PLUGIN_PATH = "${cfg.stateDir}/plugins";
        };

        path = cfg.extraPackages;

        preStart = ''
          mkdir -p "${cfg.stateDir}"
          chown -R "${cfg.user}:" "${cfg.stateDir}"
        '';

        serviceConfig = {
          ExecStart = "${package}/bin/decky-loader";
          KillMode = "process";
          TimeoutStopSec = 45;
        };
      };
      
      systemd.services.steam-cef-debug = {
        description = "Create Steam CEF debugging file for Decky Loader";
        wantedBy = [ "multi-user.target" ];
        before = [ "decky-loader.service" ];
        serviceConfig = {
          Type = "oneshot";
          User = cfg.steamUser;
          ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p ~/.steam/steam && touch ~/.steam/steam/.cef-enable-remote-debugging'";
        };
      };
    }
  ]);
}
