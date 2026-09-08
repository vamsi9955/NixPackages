{ lib, buildNpmPackage, fetchFromGitHub, writeShellScriptBin }:

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
  
  nativeBuildInputs = [ 
    # Create a fake 'git' command that completely bypasses the sandbox limitations.
    # It automatically intercepts Vite's request and echoes the first 7 characters 
    # of the GitHub revision hash we defined above.
    (writeShellScriptBin "git" ''
      echo "${builtins.substring 0 7 src.rev}"
    '')
  ];
  
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
