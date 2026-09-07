# pkgs/bookorbit/package.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm_9,           # Updated to explicitly use PNPM v9
  fetchPnpmDeps,    # The new top-level fetcher!
  pnpmConfigHook,   # The new top-level config hook!
}:

stdenv.mkDerivation rec {
  pname = "bookorbit";
  version = "1.0.0"; # Ensure this matches the tag you are targeting

  src = fetchFromGitHub {
    owner = "bookorbit";
    repo = "bookorbit";
    rev = "v${version}";
    hash = "sha256-3PSqlWG9uofu35eriNutO8TujzVUIE//xUypK1/tydc="; 
  };

  # Now using the modern, top-level fetcher
  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    hash = ""; # 2. SECOND HASH (PNPM Dependencies)
  };

  nativeBuildInputs = [
    nodejs
    pnpm_9
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    
    # Build the entire Vue client and Node backend workspace
    pnpm build
    
    # Prune development dependencies to keep your Nix store size small!
    pnpm prune --prod
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/lib/bookorbit $out/bin
    
    # Copy the compiled workspace into the Nix store
    cp -r . $out/lib/bookorbit
    
    # Create the startup wrapper that Systemd will use
    # We explicitly inject the Nix-managed PNPM v9 binary here!
    cat <<EOF > $out/bin/bookorbit
    #!/bin/sh
    cd $out/lib/bookorbit
    exec ${pnpm_9}/bin/pnpm start "\$@"
    EOF
    
    chmod +x $out/bin/bookorbit
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "Self-hosted library management, audiobooks, comics, and reading platform";
    homepage = "https://github.com/bookorbit/bookorbit";
    license = licenses.agpl3Only;
    mainProgram = "bookorbit";
  };
}
