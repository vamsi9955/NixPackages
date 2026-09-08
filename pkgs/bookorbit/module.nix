{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bookorbit;

  # --------------------------------------------------------------------------
  # DATABASE & SECRETS AUTO-PROVISIONING
  # --------------------------------------------------------------------------
  localDatabaseSetupScript = pkgs.writeShellScript "bookorbit-db-setup" ''
    set -euo pipefail
    password_file="${cfg.configDir}/database-password"

    # 1. Generate a secure database password if it doesn't exist
    if [ ! -s "$password_file" ]; then
      umask 077
      ${pkgs.coreutils}/bin/mkdir -p "${cfg.configDir}"
      ${pkgs.openssl}/bin/openssl rand -hex 24 > "$password_file"
      ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} "$password_file"
    fi
    DATABASE_PASSWORD="$(${pkgs.coreutils}/bin/cat "$password_file")"

    # 2. Inject the password securely into PostgreSQL
    # (Runs as root because of the '+' prefix in Systemd ExecStartPre)
    ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "ALTER USER ${cfg.database.user} WITH PASSWORD '$DATABASE_PASSWORD';"
  '';

  startupScript = pkgs.writeShellScript "bookorbit-start" ''
    set -euo pipefail

    DATABASE_PASSWORD="$(${pkgs.coreutils}/bin/cat ${cfg.configDir}/database-password)"
    
    jwt_file="${cfg.configDir}/jwt-secret"
    bootstrap_file="${cfg.configDir}/bootstrap-token"

    # 3. Generate cryptographic app secrets for JWT and Bootstrapping
    if [ ! -s "$jwt_file" ]; then
      umask 077
      ${pkgs.openssl}/bin/openssl rand -hex 32 > "$jwt_file"
    fi
    if [ ! -s "$bootstrap_file" ]; then
      umask 077
      ${pkgs.openssl}/bin/openssl rand -hex 16 > "$bootstrap_file"
    fi

    export JWT_SECRET="$(${pkgs.coreutils}/bin/cat "$jwt_file")"
    export SETUP_BOOTSTRAP_TOKEN="$(${pkgs.coreutils}/bin/cat "$bootstrap_file")"
    export DATABASE_URL="postgresql://${cfg.database.user}:''${DATABASE_PASSWORD}@127.0.0.1:5432/${cfg.database.name}"

    ${pkgs.coreutils}/bin/mkdir -p "${cfg.booksDir}"

    # Print the bootstrap token to the logs so you can claim your server!
    echo "=========================================================="
    echo "BookOrbit Bootstrap Token: $SETUP_BOOTSTRAP_TOKEN"
    echo "Use this token at https://${cfg.domain} to complete setup!"
    echo "=========================================================="

    # 4. Launch the application
    exec ${lib.getExe pkgs.bookorbit}
  '';

in {
  # ============================================================================
  # MODULE OPTIONS
  # ============================================================================
  options.services.bookorbit = {
    enable = mkEnableOption "Enable BookOrbit reading platform";

    domain = mkOption {
      type = types.str;
      default = "bookorbit.local";
    };

    port = mkOption { type = types.port; default = 3000; };
    openFirewall = mkOption { type = types.bool; default = false; };

    # Directory separation: Configs vs Library Data
    configDir = mkOption { type = types.str; default = "/var/lib/bookorbit"; };
    booksDir = mkOption { type = types.str; default = "/var/lib/bookorbit/books"; };

    user = mkOption { type = types.str; default = "bookorbit"; };
    group = mkOption { type = types.str; default = "bookorbit"; };

    database = {
      name = mkOption { type = types.str; default = "bookorbit"; };
      user = mkOption { type = types.str; default = "bookorbit"; };
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of paths to environment files containing custom secrets (e.g. OIDC)";
    };
  };

  # ============================================================================
  # MODULE IMPLEMENTATION
  # ============================================================================
  config = mkIf cfg.enable {

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.configDir;
    };
    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.booksDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    # Spin up PostgreSQL automatically
    services.postgresql = {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [{
        name = cfg.database.user;
        ensureDBOwnership = true;
      }];
    };

    systemd.services.bookorbit = {
      description = "BookOrbit Reading Platform";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "postgresql.service" ];
      wants = [ "network-online.target" ];
      requires = [ "postgresql.service" ];

      environment = {
        APP_URL = "https://${cfg.domain}";
        PORT = toString cfg.port;
        BOOKS_HOST_PATH = cfg.booksDir;
        NODE_ENV = "production";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.configDir;
        
        ExecStartPre = "+${localDatabaseSetupScript}";
        ExecStart = startupScript;
        
        EnvironmentFile = cfg.environmentFiles;
        Restart = "on-failure";

        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.configDir cfg.booksDir ];
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
