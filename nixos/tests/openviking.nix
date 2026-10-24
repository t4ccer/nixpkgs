{ lib, ... }:
{
  name = "openviking-modular-service";

  meta.maintainers = with lib.maintainers; [ t4ccer ];

  nodes.machine =
    { pkgs, ... }:
    {
      virtualisation.memorySize = 2048;

      environment.systemPackages = [ pkgs.curl ];

      system.services.openviking = {
        imports = [ pkgs.openviking.services.default ];
        openviking.settings = {
          server = {
            host = "127.0.0.1";
            port = 1933;
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
    };

  testScript = ''
    machine.wait_for_unit("openviking.service")
    machine.wait_for_open_port(1933)
    machine.succeed("curl -sf http://127.0.0.1:1933/health | grep -F '\"healthy\":true'")
    machine.succeed("test -d /var/lib/openviking/data/viking")
  '';
}
