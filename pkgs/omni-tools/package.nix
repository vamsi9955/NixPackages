{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "omni-tools";
  # Make sure this version string matches what nix-update expects!
  version = "0.7.0-unstable-2026-10-24"; 

  src = fetchFromGitHub {
    owner = "iib0011";
    repo = "omni-tools";
    rev = "9244e02923d99cde143ddd5b8d761d9ed0997da4";
    hash = "sha256-XQ4MwFAU5gNjQ6b1o7iQnReyAl7uHjDRgs1P3w6gzxc=";
  };

  npmDepsHash = "sha256-TPCrMwMGEJB3AquXyB+Ypl2dpgSH8QXK+UX+HSd9BkY=";
  
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
