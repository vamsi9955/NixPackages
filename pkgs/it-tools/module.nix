# pkgs/it-tools/module.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.it-tools;
in
{
  options.services.it-tools = {
    enable = lib.mkEnableOption "IT-Tools static website";

    package = lib.mkPackageOption pkgs "it-tools" { };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "it-tools.local";
      description = "The local domain name to serve IT-Tools on.";
    };
  };

  config = lib.mkIf cfg.enable {
    # If IT-Tools is enabled, ensure Caddy is also enabled
    services.caddy.enable = true;

    # Automatically generate the Caddy virtual host for the static files!
    services.caddy.virtualHosts."http://${cfg.domain}" = {
      extraConfig = ''
        root * ${cfg.package}/share/it-tools
        file_server
      '';
    };
  };
}
