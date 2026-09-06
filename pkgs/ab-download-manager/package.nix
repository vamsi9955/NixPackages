{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, xorg, libglvnd, ... }:

stdenv.mkDerivation rec {
  pname = "ab-download-manager";
  version = "2.10.3";

  src = fetchurl {
    url = "https://github.com/amir1376/ab-download-manager/releases/download/v${version}/ABDownloadManager_${version}_linux_x64.tar.gz";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  buildInputs = [
    xorg.libX11 xorg.libXrender xorg.libXext xorg.libXtst
    xorg.libXi xorg.libXcursor libglvnd
  ];

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/opt/ab-download-manager $out/bin
    cp -r * $out/opt/ab-download-manager/

    # Wrap the executable so it can find your system's graphics libraries
    makeWrapper $out/opt/ab-download-manager/ABDownloadManager $out/bin/ab-download-manager \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A desktop download manager written in Kotlin and Compose";
    homepage = "https://github.com/amir1376/ab-download-manager";
    license = licenses.gpl3Only;
    mainProgram = "ab-download-manager";
  };
}
