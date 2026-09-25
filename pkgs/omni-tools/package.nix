{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "omni-tools";
  # Make sure this version string matches what nix-update expects!
  version = "0.6.0-unstable-2026-09-25"; 

  src = fetchFromGitHub {
    owner = "iib0011";
    repo = "omni-tools";
    rev = "e8077968d5a795500815ada7bd55c0adb680bf5b";
    hash = "sha256-Z6Xxo+/viNXeJD3rtrl3tG4UlKJnJyP0txfen2CK0Dw=";
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
