{ lib, ... }:
{
  name = "openviking-modular-service";

  meta.maintainers = with lib.maintainers; [ t4ccer ];

  nodes = lib.genAttrs [ "server" "bot" ] (
    node: { pkgs, ... }: {
      virtualisation.memorySize = 2048;

      environment.systemPackages = [ pkgs.curl ];

      system.services.openviking = {
        imports = [ pkgs.openviking.services.default ];
        openviking.withBot = node == "bot";
        openviking.botPort = 18792;
        openviking.settings = {
          server = {
            host = "127.0.0.1";
            port = 1933;
          };
          bot = lib.optionalAttrs (node == "bot") {
            agents = {
              provider = "openai";
              model = "test-model";
              api_key = "test-key";
              api_base = "http://127.0.0.1:1/v1";
            };
            heartbeat.enabled = false;
            tools.cron.enabled = false;
            sandbox = {
              backend = "direct";
              backends.direct = {
                allow_exec = false;
                restrict_to_workspace = true;
              };
            };
          };
          # Dummy values, otherwise will try to fetch default model over network
          embedding.dense = {
            provider = "ollama";
            model = "qwen3-embedding:0.6b";
            api_base = "http://localhost:11434/v1";
            dimension = 1024;
          };
        };
      };
    }
  );

  testScript = ''
    import json

    start_all()
    for machine in [server, bot]:
        machine.wait_for_unit("openviking.service")
        machine.wait_for_open_port(1933)
        machine.succeed("curl -sf http://127.0.0.1:1933/health | grep -F '\"healthy\":true'")
        machine.succeed("test -d /var/lib/openviking/data/viking")

    bot.wait_for_open_port(18792)
    gateway = bot.succeed("curl -sf http://127.0.0.1:18792/health")
    assert json.loads(gateway)["healthy"] is True
    assert json.loads(gateway)["upstream_status"] == "ok"
    health = bot.succeed("curl -sf http://127.0.0.1:1933/bot/v1/health")
    assert json.loads(health)["status"] == "healthy"
    server.succeed("test $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:1933/bot/v1/health) = 503")

    bot.succeed("systemctl stop openviking.service")
    bot.wait_until_fails("curl -sf http://127.0.0.1:18792/health")
  '';
}
