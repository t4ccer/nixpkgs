{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  openssl,
  zeromq,
  cppzmq,
  tbb_2021,
  spdlog,
  libsodium,
  fmt,
  vips,
  nlohmann_json,
  libsixel,
  microsoft-gsl,
  chafa,
  cli11,
  libexif,
  range-v3,
  enableOpencv ? stdenv.hostPlatform.isLinux,
  opencv,
  enableWayland ? stdenv.hostPlatform.isLinux,
  extra-cmake-modules,
  wayland,
  wayland-protocols,
  wayland-scanner,
  enableX11 ? stdenv.hostPlatform.isLinux,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "ueberzugpp";
  version = "2.9.7";

  src = fetchFromGitHub {
    owner = "jstkdng";
    repo = "ueberzugpp";
    rev = "v${version}";
    hash = "sha256-FR05vBKIMbGiOnugkBi8IkLfHU7LzNF2ihxD7FWWYGU=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ]
  ++ lib.optionals enableWayland [
    wayland-scanner
  ];

  buildInputs = [
    openssl
    zeromq
    cppzmq
    tbb_2021
    spdlog
    libsodium
    fmt
    vips
    nlohmann_json
    libsixel
    microsoft-gsl
    chafa
    cli11
    libexif
    range-v3
  ]
  ++ lib.optionals enableOpencv [
    opencv
  ]
  ++ lib.optionals enableWayland [
    extra-cmake-modules
    wayland
    wayland-protocols
  ]
  ++ lib.optionals enableX11 [
    xorg.libX11
    xorg.xcbutilimage
  ];

  cmakeFlags =
    lib.optionals (!enableOpencv) [
      "-DENABLE_OPENCV=OFF"
    ]
    ++ lib.optionals enableWayland [
      "-DENABLE_WAYLAND=ON"
    ]
    ++ lib.optionals (!enableX11) [
      "-DENABLE_X11=OFF"
    ];

  meta = with lib; {
    description = "Drop in replacement for ueberzug written in C++";
    homepage = "https://github.com/jstkdng/ueberzugpp";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      aleksana
      wegank
    ];
    platforms = platforms.unix;
  };
}
