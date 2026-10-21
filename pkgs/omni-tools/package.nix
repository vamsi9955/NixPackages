{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "omni-tools";
  # Make sure this version string matches what nix-update expects!
  version = "0.7.0-unstable-2026-10-20"; 

  src = fetchFromGitHub {
    owner = "iib0011";
    repo = "omni-tools";
    rev = "dda3a240772459035eb38b14c5c7d94e81626116";
    hash = "sha256-Qr0Dq0uwD+K9KqlMKVKgEbzMN76WEnM4NcRBY9/af4o=";
  };

  npmDepsHash = "sha256-UsgxAAvzo8eN9O7X1F7aooLlFP80ZSAdk7xawnXHgto=";
  
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
