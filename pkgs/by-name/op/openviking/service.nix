# Non-module dependencies (`importApply`)
{ formats }:

# Service module
{
  config,
  lib,
  options,
  name,
  ...
}:
let
  cfg = config.openviking;
  settingsFormat = formats.json { };
  configFile = "ov.conf";
  configOutPath = config.configData.${configFile}.path;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [ t4ccer ];

  options.openviking = {
    package = lib.mkOption {
      description = "Package to use for OpenViking.";
      defaultText = "The OpenViking package that provided this module.";
      type = lib.types.package;
    };

    botPackage = lib.mkOption {
      type = lib.types.package;
      default = cfg.package.override { withBot = true; };
      defaultText = lib.literalExpression "config.openviking.package.override { withBot = true; }";
      description = "OpenViking package to use when the managed bot is enabled.";
    };

    withBot = lib.mkEnableOption "the managed VikingBot gateway and Studio chat API";

    botPort = lib.mkOption {
      type = lib.types.port;
      default = 18790;
      description = ''
        Loopback port for the managed VikingBot gateway. This is an internal
        endpoint; clients should use the authenticated OpenViking Bot API.
      '';
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      example = {
        server = {
          host = "127.0.0.1";
          port = 1933;
        };
        embedding.dense = {
          provider = "ollama";
          model = "qwen3-embedding:0.6b";
          api_base = "http://localhost:11434/v1";
          dimension = 1024;
        };
      };
      description = ''
        Configuration written to `ov.conf`, see
        <https://github.com/volcengine/OpenViking/blob/main/examples/ov.conf.example>
        for the available options.

        When `withBot` is enabled, configure the gateway through the `bot`
        section of these same settings. It inherits the root `vlm` model unless
        overridden in `bot.agents`. The packaged bot supports the direct sandbox,
        web tools and scheduling; other channels and sandbox backends may need
        additional dependencies. The direct sandbox can execute commands as the
        service user by default; set `bot.sandbox.backends.direct.allow_exec` to
        false to disable this and `restrict_to_workspace` to true to restrict
        file access. The systemd service's sandbox remains in effect.

        `$VAR` and `''${VAR}` references are expanded from the environment when the
        configuration is loaded, so secrets can be kept out of the Nix store by
        referencing variables provided through e.g. an environment file.
      '';
    };
  };

  config = {
    openviking.settings.storage.workspace = lib.mkDefault "/var/lib/${name}/data";

    process.argv = [
      (lib.getExe' (if cfg.withBot then cfg.botPackage else cfg.package) "openviking-server")
      "--config"
      configOutPath
    ]
    ++ lib.optionals cfg.withBot [
      "--with-bot"
      "--bot-port"
      (toString cfg.botPort)
      # Let the service manager collect gateway output instead of log files.
      "--disable-bot-logging"
    ];

    configData.${configFile}.source = settingsFormat.generate configFile cfg.settings;
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.service = {
      description = "OpenViking context database server";
      documentation = [ "https://github.com/volcengine/OpenViking" ];

      after = [ "network.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [ config.configData.${configFile}.source ];

      # Downloaded models are cached in ~/.cache/openviking
      environment.HOME = "/var/lib/${name}";

      serviceConfig = {
        Restart = "on-failure";

        StateDirectory = name;
        StateDirectoryMode = "0700";
        WorkingDirectory = "%S/${name}";
        BindReadOnlyPaths = [ configOutPath ];

        User = name;
        DynamicUser = true;
        UMask = "0077";

        # systemd service hardening
        CapabilityBoundingSet = "";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [ "@system-service" ];
      };
    };
  };
}
