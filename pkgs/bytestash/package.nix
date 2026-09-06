# pkgs/bytestash/package.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs_22,
  python3,
  makeWrapper,
}:

let
  version = "1.5.11"; # Latest stable release

  src = fetchFromGitHub {
    owner = "jordan-dalby";
    repo = "ByteStash";
    rev = "v${version}";
    hash = "sha256-aRVKqfFELQuPkQrABJzIEdTmRSXgQf9z/zGS2W8akiQ="; 
  };

  # The exact hash you successfully generated!
  sharedNpmDepsHash = "sha256-8VgtXM+0yFsFDAY6hzECkCGov77wDnAmB+I9V9JYEyQ="; 

  # ---------------------------------------------------------
  # 1. Build the React Frontend
  # ---------------------------------------------------------
  frontend = buildNpmPackage {
    pname = "bytestash-frontend";
    inherit version src;

    npmDepsHash = sharedNpmDepsHash; 
    nodejs = nodejs_22; 

    npmWorkspace = "client";

    installPhase = ''
      runHook preInstall
      
      cp -r client/build $out
      
      runHook postInstall
    '';
  };

in
# ---------------------------------------------------------
# 2. Build the Express.js Backend (Main Package)
# ---------------------------------------------------------
buildNpmPackage {
  pname = "bytestash";
  inherit version src;
  
  npmDepsHash = sharedNpmDepsHash; 
  nodejs = nodejs_22;

  npmWorkspace = "server";
  dontNpmBuild = true;

  nativeBuildInputs = [
    python3
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/bytestash
    cp -r server $out/lib/bytestash/
    cp -r node_modules $out/lib/bytestash/

    rm -f $out/lib/bytestash/node_modules/bytestash-client

    # ---------------------------------------------------------
    # THE FRONTEND INJECTION
    # Put the compiled frontend EXACTLY where the backend 
    # expects to find it (../../client/build)
    # ---------------------------------------------------------
    mkdir -p $out/lib/bytestash/client/build
    cp -r ${frontend}/* $out/lib/bytestash/client/build/

    # Route database writes from the immutable Nix store directly 
    # to your writable Systemd StateDirectory
    ln -s /var/lib/bytestash $out/lib/bytestash/data

    mkdir -p $out/bin

    makeWrapper ${lib.getExe nodejs_22} $out/bin/bytestash \
      --add-flags "$out/lib/bytestash/server/src/app.js" \
      --set NODE_ENV production

    runHook postInstall
  '';
  meta = {
    description = "A code snippet storage solution written in React & Node.js";
    homepage = "https://github.com/jordan-dalby/ByteStash";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ];
    mainProgram = "bytestash";
  };
}
