{ lib, rustPlatform, fetchFromGitHub, pkg-config, openssl }:

rustPlatform.buildRustPackage rec {
  pname = "cargo-leptos";
  version = "0.1.8";

  src = fetchFromGitHub {
    owner = "leptos-rs";
    repo = pname;
    rev = version;
    hash = "sha256-z4AqxvKu9E8GGMj6jNUAAWeqoE/j+6NoAEZWeNZ+1BA=";
  };

  cargoSha256 = "sha256-w/9W4DXbh4G5DZ8IGUz4nN3LEjHhL7HgybHqODMFzHw=";

  # This feature disables automatic download of runtime dependencies like
  # sass, tailwind, cargo-generate, and binaryen
  buildFeatures = [ "no_downloads" ];

  buildInputs = [ openssl ];
  nativeBuildInputs = [ pkg-config ];

  # Tests require Internet connection
  doCheck = false;

  meta = with lib; {
    description = "Build tool for Leptos";
    homepage = "https://github.com/leptos-rs/cargo-leptos";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ t4ccer ];
  };
}
