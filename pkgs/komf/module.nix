{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.komf;

  # Use Nix's built-in YAML generator
  yamlFormat = pkgs.formats.yaml { };
  
  # Base required settings (port binding and database path)
  defaultSettings = {
    server = {
      port = cfg.port;
    };
    database = {
      file = "${cfg.dataDir}/database.sqlite";
    };
  };

  # Merge defaults with user settings and generate the config file
  configFile = yamlFormat.generate "application.yml" (recursiveUpdate defaultSettings cfg.settings);

  startupScript = pkgs.writeShellScript "komf-start" ''
    set -euo pipefail

    # Spring Boot automatically reads application.yml from the working directory.
    # We copy it dynamically so the Nix store remains immutable, but the app can boot.
    cp -f ${configFile} ${cfg.dataDir}/application.yml
    chmod 644 ${cfg.dataDir}/application.yml

    exec ${lib.getExe cfg.package}
  '';

in {
  options.services.komf = {
    enable = mkEnableOption "Komf metadata fetcher";
    package = mkPackageOption pkgs "komf" { };
    
    port = mkOption { type = types.port; default = 8085; };
    openFirewall = mkOption { type = types.bool; default = false; };
    
    dataDir = mkOption { 
      type = types.str; 
      default = "/var/lib/komf"; 
    };

    user = mkOption { type = types.str; default = "komf"; };
    group = mkOption { type = types.str; default = "komf"; };

    settings = mkOption {
      type = yamlFormat.type;
      default = {};
      description = "Declarative application.yml configuration for Komf.";
      example = literalExpression ''
        {
          komga = {
            baseUri = "http://localhost:25600";
            komgaUser = "\''${KOMGA_USER}";
            komgaPassword = "\''${KOMGA_PASSWORD}";
          };
        }
      '';
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to an environment file containing secrets (e.g., /run/secrets/komf.env)";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };
    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.komf = {
      description = "Komf Metadata Fetcher";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        
        ExecStart = startupScript;
        Restart = "on-failure";
        
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;

        # Hardening
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.dataDir ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
      };
    };

    networking.firewall = mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
