# pkgs/omni-tools/package.nix
{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "omni-tools";
  version = "latest";

  src = fetchFromGitHub {
    owner = "iib0011";
    repo = "omni-tools";
    rev = "main";
    hash = "sha256-4FLerVHkwlTPqmpXvxr9A4Bkk9U2SGMGoqwRulXXHQ4=";
  };

  npmDepsHash = "sha256-dIHy1k8id5JmxmCM/x4GiQciFPU0/i+z2snOOYRVq68=";

  # By default, buildNpmPackage automatically runs 'npm run build' for us.
  
  installPhase = ''
    runHook preInstall
    
    # We grab the static output from the 'dist' folder and discard the rest
    mkdir -p $out/share/omni-tools
    cp -r dist/* $out/share/omni-tools/
    
    runHook postInstall
  '';

  meta = {
    description = "Self-hosted collection of powerful web-based tools";
    homepage = "https://github.com/iib0011/omni-tools";
  };
}
