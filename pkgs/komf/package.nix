{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  jre_headless,
}:

stdenvNoCC.mkDerivation rec {
  pname = "komf";
  version = "1.7.1";

  src = fetchurl {
    url = "https://github.com/Snd-R/komf/releases/download/${version}/komf-${version}.jar";
    hash = "sha256-reVCSNj4FlKILXSRuRw/m7uv/SjTXS0Ch1snrNWJBNE=";
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
