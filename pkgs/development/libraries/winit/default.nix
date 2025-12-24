{
  lib,

  libxkbcommon,
  libGL,
  wayland,
  xorg,

  makeSetupHook,
  makeBinaryWrapper,
}:

{
  # GUI applications based on the winit crate expect to dlopen window libraries
  wrapWinitAppsHook = makeSetupHook {
    name = "wrap-winit-apps-hook";
    propagatedBuildInputs = [ makeBinaryWrapper ];
    substitutions = {
      # https://github.com/emilk/egui/discussions/1587#discussioncomment-2698797
      winitRuntimeInputs = lib.makeLibraryPath [
        libxkbcommon
        libGL

        # WINIT_UNIX_BACKEND=wayland
        wayland

        # WINIT_UNIX_BACKEND=x11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libX11
      ];
    };
  } ./wrap-winit-apps-hook.sh;
}
