# pkgs/mazanoke/package.nix
{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "mazanoke";
  version = "1.1.7-unstable-2026-09-20";

  src = fetchFromGitHub {
    owner = "civilblur";
    repo = "mazanoke";
    rev = "ceab516ade2a68f3c0abef8bd8fa03ada3ac3e7b";
    hash = "sha256-Qh67Zd10gSLUTHIXdlxvigxBG1elqfl4jF9fFPZMmfU=";
  };

  # No nativeBuildInputs needed! It requires no compilation.
  
  installPhase = ''
    runHook preInstall
    
    # We output purely to the 'share' directory since there are no binaries
    mkdir -p $out/share/mazanoke
    cp -r * $out/share/mazanoke/
    
    runHook postInstall
  '';

  meta = {
    description = "A self-hosted local image optimizer that runs in your browser";
    homepage = "https://github.com/civilblur/mazanoke";
    license = lib.licenses.gpl3;
  };
}
