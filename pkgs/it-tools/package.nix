# pkgs/it-tools/package.nix
{ 
  lib, 
  stdenv, 
  fetchFromGitHub, 
  nodejs_22, 
  pnpm, 
  fetchPnpmDeps,
  pnpmConfigHook,
}:

stdenv.mkDerivation rec {
  pname = "it-tools";
  version = "2024.10.22-7ca5933-unstable-2026-02-12";

  src = fetchFromGitHub {
    owner = "CorentinTh";
    repo = "it-tools";
    rev = "d505845f918e946ec300af7b36efc107e2f66e9e";
    # 1st Hash: The source code hash
    hash = "sha256-dWVRiLbJ1X4yHT5yRcq+KaHmjjtc24yQg0jQvWTPNwU="; 
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src pnpm;
    fetcherVersion = 4;
    hash = "sha256-ju8YO0IHIGJtCi5TnxvfLUXcTqKWnTBKAGFBhzQJTok=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    
    pnpm run build
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share/it-tools
    cp -r dist/* $out/share/it-tools/
    
    runHook postInstall
  '';

  meta = {
    description = "Collection of handy online tools for developers, with great UX";
    homepage = "https://github.com/CorentinTh/it-tools";
    license = lib.licenses.gpl3Plus;
  };
}
