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
  version = "latest";

  src = fetchFromGitHub {
    owner = "CorentinTh";
    repo = "it-tools";
    rev = "main";
    # 1st Hash: The source code hash
    hash = "sha256-dWVRiLbJ1X4yHT5yRcq+KaHmjjtc24yQg0jQvWTPNwU="; 
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    # 2nd Hash: The PNPM dependencies cache
    hash = "sha256-+/q9cu8WG8qzMBbocfnrcsHI2Kd1ztO7mXk3xvwQEfs=";
    
    # NEW: Tell Nix which lockfile algorithm to use
    fetcherVersion = 3; 
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
