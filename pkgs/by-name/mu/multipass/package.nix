{
  callPackage,
  fetchFromGitHub,
  lib,
  nixosTests,
  stdenv,
  symlinkJoin,
}:

let
  name = "multipass";
  version = "1.16.0";

  multipass_src = fetchFromGitHub {
    owner = "canonical";
    repo = "multipass";
    rev = "refs/tags/v${version}";
    hash = "sha256-7P7LZEvZ+ygM0G8C/gMIwq5BOSs4wSVEBNgsaZzBbOk=";
    fetchSubmodules = true;
  };

  commonMeta = {
    homepage = "https://multipass.run";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jnsgruk ];
    platforms = [ "x86_64-linux" ];
  };

  multipassd = callPackage ./multipassd.nix {
    inherit commonMeta multipass_src version;
  };

  multipass-gui = callPackage ./gui.nix {
    inherit
      commonMeta
      multipass_src
      multipassd
      version
      ;
  };
in
symlinkJoin {
  inherit version;
  pname = name;

  paths = [
    multipassd
    multipass-gui
  ];

  passthru = {
    tests = lib.optionalAttrs stdenv.hostPlatform.isLinux {
      inherit (nixosTests) multipass;
    };
    updateScript = ./update.sh;
  };

  meta = commonMeta // {
    description = "Ubuntu VMs on demand for any workstation";
  };
}
