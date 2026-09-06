# pkgs/mazanoke/package.nix
{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "mazanoke";
  version = "1.1.6-unstable-2026-05-10";

  src = fetchFromGitHub {
    owner = "civilblur";
    repo = "mazanoke";
    rev = "68d6a24429fd58feec2808a3f5ee0062fef744d6";
    hash = "sha256-b9tEK0fnrTIOG16jxPbAI+25G4TF3P8SKpVkb99Unqw=";
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
