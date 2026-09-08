{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, libx11
, libxrender
, libxext
, libxtst
, libxi
, libxcursor
, libglvnd
, fontconfig
, freetype
, alsa-lib
, zlib
, wayland
, libxkbcommon
}:

stdenv.mkDerivation rec {
  pname = "ab-download-manager";
  version = "1.10.4";

  src = fetchurl {
    url = "https://github.com/amir1376/ab-download-manager/releases/download/v1.10.4/ABDownloadManager_1.10.4_linux_x64.tar.gz";
    hash = "sha256-X5O7qI5WuHKvVbuOGWXZAovkqIhhmwxJswQoEysfwWk=";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  buildInputs = [
    # X11 Fallback Libraries
    libx11 libxrender libxext libxtst libxi libxcursor 
    
    # Native Wayland & Graphics Libraries
    wayland libxkbcommon libglvnd 
    
    # Fonts, Audio, and Core C++ Utils
    fontconfig freetype alsa-lib zlib stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/opt/ab-download-manager $out/bin $out/share/applications $out/share/pixmaps
    cp -r bin lib $out/opt/ab-download-manager/
    cp $out/opt/ab-download-manager/lib/ABDownloadManager.png $out/share/pixmaps/ab-download-manager.png

    # Wrap the executable so it can dynamically locate the Wayland/X11 libraries on your system
    makeWrapper $out/opt/ab-download-manager/bin/ABDownloadManager $out/bin/ab-download-manager \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --set SKIKO_RENDER_API "SOFTWARE"

    cat <<EOF > $out/share/applications/ab-download-manager.desktop
    [Desktop Entry]
    Name=AB Download Manager
    Comment=A Download Manager that speeds up your downloads
    GenericName=Download Manager
    Exec=ab-download-manager
    Icon=ab-download-manager
    Terminal=false
    Type=Application
    Categories=Network;Utility;
    StartupWMClass=com-abdownloadmanager-desktop-AppKt
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "A desktop download manager written in Kotlin and Compose";
    homepage = "https://github.com/amir1376/ab-download-manager";
    license = licenses.gpl3Only;
    mainProgram = "ab-download-manager";
    platforms = [ "x86_64-linux" ];
  };
}
