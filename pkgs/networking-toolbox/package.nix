# pkgs/networking-toolbox/package.nix
{ 
  lib, 
  buildNpmPackage, 
  fetchFromGitHub, 
  nodejs_22, 
  makeWrapper,
  autoPatchelfHook,
  stdenv
}:

buildNpmPackage rec {
  pname = "networking-toolbox";
  version = "1.6.0-unstable-2026-04-05";

  src = fetchFromGitHub {
    owner = "lissy93";
    repo = "networking-toolbox";
    rev = "776805f692c20e59fe5de1942e999ccf91944f54";
    hash = "sha256-7c96qlv+5j8rk4U8hiPYKy0sdm2tsYx+XH158jU0GqQ="; 
  };

  npmDepsHash = "sha256-Ua0vJIobjmvm6L/r2RBvEZd2l6kH6mg3JBzRwGhmbB4=";

  DEPLOY_ENV = "node";

  # Prevent Node.js from running out of memory during massive rollup bundling
  NODE_OPTIONS = "--max-old-space-size=8192";

  # 1. Bring in autoPatchelfHook to fix the binaries
  nativeBuildInputs = [ makeWrapper autoPatchelfHook ];
  
  # 2. Provide the standard C++ libraries that the dart-sass binary needs to run
  buildInputs = [ stdenv.cc.cc.lib ];

  preBuild = ''
    # Delete Alpine Linux (musl) binaries since NixOS uses glibc.
    rm -rf node_modules/*-musl* node_modules/@*/*-musl*
    
    autoPatchelf node_modules
    
    # 3. Disable SvelteKit's crawler and strict routing errors. 
    # The crawler hangs when trying to fetch external icons in the Nix sandbox, 
    # causing the build to timeout or get terminated.
    node -e "
    const fs = require('fs');
    let content = fs.readFileSync('svelte.config.js', 'utf8');
    
    content = content.replace(/export default\s+/, 'const _nix_config = ');
    
    content += '\n_nix_config.kit = _nix_config.kit || {};';
    content += '\n_nix_config.kit.prerender = _nix_config.kit.prerender || {};';
    content += '\n_nix_config.kit.prerender.handleUnseenRoutes = \"ignore\";';
    content += '\n_nix_config.kit.prerender.handleHttpError = \"ignore\";';
    
    // Disable crawling completely to prevent sandbox network timeouts
    content += '\n_nix_config.kit.prerender.crawl = false;';
    
    content += '\nexport default _nix_config;';
    
    fs.writeFileSync('svelte.config.js', content);
    "
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/lib/networking-toolbox
    cp -r build package.json node_modules $out/lib/networking-toolbox/
    
    mkdir -p $out/bin
    makeWrapper ${lib.getExe nodejs_22} $out/bin/networking-toolbox \
      --add-flags "$out/lib/networking-toolbox/build/index.js" \
      --set NODE_ENV production
      
    runHook postInstall
  '';

  meta = {
    description = "100+ offline-first networking tools and utilities";
    homepage = "https://github.com/lissy93/networking-toolbox";
  };
}
