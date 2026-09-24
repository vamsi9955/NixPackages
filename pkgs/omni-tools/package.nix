{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "omni-tools";
  # Make sure this version string matches what nix-update expects!
  version = "0.6.0-unstable-2026-09-24"; 

  src = fetchFromGitHub {
    owner = "iib0011";
    repo = "omni-tools";
    rev = "ceaedcb1f035b1ab2464f76bcf77df2ab6be8bb7";
    hash = "sha256-5r4f8oidUQQvrUd5Dj2R5PCiEixxCgNksnZy0sebH8w=";
  };

  npmDepsHash = "sha256-DoWNUDmpaJAUVHRn3GnEI63QaEb8Te2WwYwJerFN+Ak=";
  
  # This phase safely edits the file in-place before the build starts.
  # When Vite calls execSync(), it will run our echo command instead of git.
  postPatch = ''
    substituteInPlace vite.config.ts \
      --replace-warn "git rev-parse --short HEAD" "echo ${builtins.substring 0 7 src.rev}"
  '';
  
  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share/omni-tools
    cp -r dist/* $out/share/omni-tools/
    
    runHook postInstall
  '';

  meta = {
    description = "Self-hosted collection of powerful web-based tools";
    homepage = "https://github.com/iib0011/omni-tools";
  };
}
