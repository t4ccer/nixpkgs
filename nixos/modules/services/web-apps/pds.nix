{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.pds;

  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    escapeShellArgs
    concatMapStringsSep
    types
    literalExpression
    ;

  pdsadminWrapper =
    let
      cfgSystemd = config.systemd.services.pds.serviceConfig;
    in
    pkgs.writeShellScriptBin "pdsadmin" ''
      DUMMY_PDS_ENV_FILE="$(mktemp)"
      trap 'rm -f "$DUMMY_PDS_ENV_FILE"' EXIT
      env "PDS_ENV_FILE=$DUMMY_PDS_ENV_FILE"                                                   \
          ${escapeShellArgs cfgSystemd.Environment}                                            \
          ${concatMapStringsSep " " (envFile: "$(cat ${envFile})") cfgSystemd.EnvironmentFile} \
          ${getExe pkgs.pdsadmin} "$@"
    '';
in
# All defaults are from https://github.com/bluesky-social/pds/blob/8b9fc24cec5f30066b0d0b86d2b0ba3d66c2b532/installer.sh
{
  options.services.pds = {
    enable = mkEnableOption "pds";

    package = mkPackageOption pkgs "pds" { };

    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf (types.nullOr types.str);
        options = {
          PDS_PORT = mkOption {
            type = types.str;
            default = "3000";
            description = "Port to listen on";
          };

          PDS_HOSTNAME = mkOption {
            type = types.str;
            example = "pds.example.com";
            description = "Instance hostname (base domain name)";
          };

          PDS_BLOB_UPLOAD_LIMIT = mkOption {
            type = types.str;
            default = "52428800";
            description = "Size limit of uploaded blobs";
          };

          PDS_DID_PLC_URL = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "URL of DID PLC directory";
          };

          PDS_BSKY_APP_VIEW_URL = mkOption {
            type = types.str;
            default = "https://api.bsky.app";
            description = "URL of bsky frontend";
          };

          PDS_BSKY_APP_VIEW_DID = mkOption {
            type = types.str;
            default = "did:web:api.bsky.app";
            description = "DID of bsky frontend";
          };

          PDS_REPORT_SERVICE_URL = mkOption {
            type = types.str;
            default = "https://mod.bsky.app";
            description = "URL of mod service";
          };

          PDS_REPORT_SERVICE_DID = mkOption {
            type = types.str;
            default = "did:plc:ar7c4by46qjdydhdevvrndac";
            description = "DID of mod service";
          };

          PDS_CRAWLERS = mkOption {
            type = types.str;
            default = "https://bsky.network";
            description = "URL of crawlers";
          };

          PDS_DATA_DIRECTORY = mkOption {
            type = types.str;
            default = "/var/lib/pds";
            description = "Directory to store state";
          };

          PDS_BLOBSTORE_DISK_LOCATION = mkOption {
            type = types.nullOr types.str;
            default = "/var/lib/pds/blocks";
            description = "Store blobs at this location, set to null to use e.g. S3";
          };

          LOG_ENABLED = mkOption {
            type = types.nullOr types.str;
            default = "true";
            description = "Enable logging";
          };
        };
      };

      description = ''
        Environment variables to set for the service. Secrets should be
        specified using {option}`environmentFile`.

        Refer to <https://github.com/bluesky-social/atproto/blob/92cd7a84ad207278c241afce8c8491e73b0a24e0/packages/pds/src/config/env.ts> for available environment variables.
      '';
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        File to load environment variables from. Loaded variables override
        values set in {option}`environment`.

        Use it to set values of `PDS_JWT_SECRET`, `PDS_ADMIN_PASSWORD`,
        and `PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX` secrets.
        You can generate initial values with
        ```
        nix-build -A pds.passthru.generateSecrets
        ./result/bin/generate-pds-secrets > secrets.env
        ```
      '';
    };

    pdsadmin = {
      enable = mkOption {
        type = types.bool;
        default = cfg.enable;
        defaultText = literalExpression "services.pds.enable";
        description = "Add pdsadmin script to PATH";
      };

      useServiceEnvironment = mkOption {
        type = types.bool;
        default = true;
        description = "Inherit environment variables of pds systemd unit";
      };
    };
  };

  config = mkIf cfg.enable {
    environment = mkIf cfg.pdsadmin.enable {
      systemPackages = [
        (if cfg.pdsadmin.useServiceEnvironment then pdsadminWrapper else pkgs.pdsadmin)
      ];
    };

    systemd.services.pds = {
      description = "pds";
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = getExe cfg.package;
        Environment = lib.mapAttrsToList (k: v: "${k}=${v}") (
          lib.filterAttrs (_: v: v != null) cfg.settings
        );

        EnvironmentFile = cfg.environmentFiles;
        User = "pds";
        Group = "pds";
        StateDirectory = "pds";
        StateDirectoryMode = "0755";
        Restart = "always";
      };
    };

    users = {
      users.pds = {
        group = "pds";
        createHome = false;
        isSystemUser = true;
      };
      groups.pds = { };
    };

  };

  meta.maintainers = with lib.maintainers; [ t4ccer ];
}
