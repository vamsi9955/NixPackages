# pkgs/calibre-web-automated/module.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.calibre-web-automated;
  dataDir = if lib.hasPrefix "/" cfg.dataDir then cfg.dataDir else "/var/lib/${cfg.dataDir}";
in
{
  options = {
    services.calibre-web-automated = {
      enable = lib.mkEnableOption "Calibre-Web-Automated";

      package = lib.mkPackageOption pkgs "calibre-web-automated" { };

      listen = {
        ip = lib.mkOption {
          type = lib.types.str;
          default = "::1";
          description = "IP address that Calibre-Web-Automated should listen on (use 0.0.0.0 for all interfaces).";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8083;
          description = "Listen port for Calibre-Web-Automated.";
        };
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "calibre-web-automated";
        description = "Where Calibre-Web-Automated stores its data. Either an absolute path, or the directory name below /var/lib.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "calibre-web-automated";
        description = "User account under which Calibre-Web-Automated runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "calibre-web-automated";
        description = "Group account under which Calibre-Web-Automated runs.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open ports in the firewall for the server.";
      };

      options = {
        calibreLibrary = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to your Calibre library directory (must contain metadata.db).";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.settings = lib.optionalAttrs (lib.hasPrefix "/" cfg.dataDir) {
      "10-calibre-web-automated".${dataDir}.d = {
        inherit (cfg) user group;
        mode = "0700";
      };
    };

    systemd.services.calibre-web-automated =
      let
        appDb = "${dataDir}/app.db";
        gdriveDb = "${dataDir}/gdrive.db";
        calibreWebCmd = "${cfg.package}/bin/calibre-web-automated -p ${appDb} -g ${gdriveDb}";
      in
      {
        description = "Calibre-Web Automated Service";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment.CACHE_DIR = "/var/cache/calibre-web-automated";

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          # Force the app to execute inside our writable data directory!
          WorkingDirectory = dataDir; 

          ExecStartPre = lib.optionalString (cfg.options.calibreLibrary != null) ''
            ${pkgs.coreutils}/bin/test -f "${cfg.options.calibreLibrary}/metadata.db" || { echo "Invalid Calibre library path: metadata.db not found"; exit 1; }
          '';

          ExecStart = "${calibreWebCmd} -i ${cfg.listen.ip}";
          Restart = "on-failure";

          CacheDirectory = "calibre-web-automated";
          CacheDirectoryMode = "0750";

          # Systemd Hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ReadWritePaths =
            lib.optional (lib.hasPrefix "/" cfg.dataDir) cfg.dataDir
            ++ lib.optional (cfg.options.calibreLibrary != null) cfg.options.calibreLibrary;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateIPC = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictSUIDSGID = true;
          
          # Changed from true to read-only so it can read libraries stored in /home/vamsi/
          ProtectHome = "read-only"; 
          
          ProtectProc = "invisible";
          ProcSubset = "pid";
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
          RestrictNamespaces = true;
          RemoveIPC = true;
          ProtectKernelModules = true;
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
        } // lib.optionalAttrs (!(lib.hasPrefix "/" cfg.dataDir)) {
          StateDirectory = cfg.dataDir;
        };
      };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.listen.port ];
    };

    users.users = lib.mkIf (cfg.user == "calibre-web-automated") {
      calibre-web-automated = {
        isSystemUser = true;
        group = cfg.group;
      };
    };

    users.groups = lib.mkIf (cfg.group == "calibre-web-automated") {
      calibre-web-automated = { };
    };
  };
}
