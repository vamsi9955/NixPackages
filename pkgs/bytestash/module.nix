# pkgs/bytestash/module.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.bytestash;
in
{
  options.services.bytestash = {
    enable = lib.mkEnableOption "ByteStash snippet manager";

    package = lib.mkPackageOption pkgs "bytestash" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
      description = "The port ByteStash will listen on.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "bytestash";
      description = "The directory under /var/lib/ where the SQLite database is stored.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.bytestash = {
      description = "ByteStash Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      # Expose the requested port to the Node.js application
      environment = {
        PORT = toString cfg.port;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/bytestash";
        Restart = "on-failure";

        # This automatically creates /var/lib/bytestash and routes the app there
        StateDirectory = cfg.dataDir;
        WorkingDirectory = "/var/lib/${cfg.dataDir}";
        
        # Security hardening: Run as an isolated dynamic user
        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
      };
    };
  };
}
