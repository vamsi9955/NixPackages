# pkgs/grimmory/package.nix
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
  zip,
  openjdk25_headless,
  ffmpeg,
  kepubify,
  libarchive,
}:

stdenvNoCC.mkDerivation rec {
  pname = "grimmory";
  version = "3.3.3";

  src = fetchurl {
    url = "https://github.com/grimmory-tools/grimmory/releases/download/v3.3.3/grimmory.jar";
    hash = "sha256-L77JlO6+bqFaBoMLAhfuCU3wSA9KAoSC66Mb7fC5SK4=";
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
    zip
  ];

  dontUnpack = true;

  installPhase = ''
      runHook preInstall

      mkdir -p $out/share/grimmory
      install -Dm644 $src $out/share/grimmory/grimmory.jar

      makeWrapper ${lib.getExe' openjdk25_headless "java"} $out/bin/grimmory \
        --prefix PATH : ${lib.makeBinPath [ ffmpeg kepubify ]} \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libarchive ]} \
        --add-flags "--enable-native-access=ALL-UNNAMED" \
        --add-flags "--enable-preview" \
        --add-flags "-jar $out/share/grimmory/grimmory.jar"

      runHook postInstall
    '';

  meta = {
    description = "Self-hosted, multi-user digital library with smart shelves, metadata, Kobo and KOReader sync, OPDS, and a built-in reader";
    homepage = "https://github.com/grimmory-tools/grimmory";
    license = lib.licenses.agpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    mainProgram = "grimmory";
    platforms = [ "x86_64-linux" ];
  };
}
