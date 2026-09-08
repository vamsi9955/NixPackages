# pkgs/omni-tools/package.nix
{ lib, buildNpmPackage, fetchFromGitHub, git }:

buildNpmPackage rec {
  pname = "omni-tools";
  version = "0.6.0-unstable-2026-08-17";

  src = fetchFromGitHub {
    owner = "iib0011";
    repo = "omni-tools";
    rev = "89a50e3e3d221b4291cce7cbf91db6f4b0790679";
    hash = "sha256-EffnnFkiUc9e1EfKHPMdxR/qXzu5Clmu2rbKPgU9mtI=";
  };

  npmDepsHash = "sha256-DoWNUDmpaJAUVHRn3GnEI63QaEb8Te2WwYwJerFN+Ak=";
  
  nativeBuildInputs = [ git ];
  
  preBuild = ''
    # Initialize git repo in the build directory before npm build runs
    cd "$sourceRoot"
    git init
    git config user.email "nix@localhost"
    git config user.name "Nix Builder"
    git add .
    git commit -m "Initial commit" --no-verify 2>/dev/null || true
  '';
  
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
