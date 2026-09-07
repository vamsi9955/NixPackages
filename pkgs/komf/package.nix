{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  jre_headless,
}:

stdenvNoCC.mkDerivation rec {
  pname = "komf";
  version = "2.0.1";

  src = fetchurl {
    url = "https://github.com/Snd-R/komf/releases/download/2.0.1/komf-2.0.1.jar";
    hash = "sha256-9eAaBpOM8eE6Tp2CEdsFaeieCSVgctG731sEKR6AnLk=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/share/komf
    install -Dm644 $src $out/share/komf/komf.jar

    # Create the startup wrapper
    makeWrapper ${lib.getExe jre_headless} $out/bin/komf \
      --add-flags "-jar $out/share/komf/komf.jar"
      
    runHook postInstall
  '';

  meta = with lib; {
    description = "Komga and Kavita metadata fetcher";
    homepage = "https://github.com/Snd-R/komf";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    mainProgram = "komf";
  };
}
