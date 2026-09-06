{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  nixosTests,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "calibre-web-automated";
  # Update this to match the tag or date you are trying to package
  version = "unstable-2026-06-02"; 
  pyproject = true;

  src = fetchFromGitHub {
    owner = "crocodilestick";
    repo = "Calibre-Web-Automated";
    # Pin this to a specific commit hash or release tag (e.g., "v4.0.6")
    rev = "main"; 
    # Leave as fakeHash for the first run. Nix will fail and give you the correct SRI hash to paste here.
    hash = "sha256-w1jFzjg00bB8H/AzzCc9gdc6guxbzCLUWSGLZpfD40c="; 
  };

  patches = [
    # WARNING: The patches from janeczku/calibre-web (default-logger.patch and db-migrations.patch) 
    # belong to the nixpkgs tree and may no longer apply cleanly to the crocodilestick fork due to 
    # heavy backend modifications. It is highly recommended to leave these commented out initially.
    # ./default-logger.patch
    # ./db-migrations.patch
  ];

# CWA mostly maintains the same directory structure, but adds new top-level
  # scripts (like cwa_db.py in the scripts/ folder) that don't get packaged automatically. 
postPatch = ''
    mkdir -p src/calibreweb
    mv cps.py src/calibreweb/__init__.py
    mv cps src/calibreweb

    # CWA heavily uses a "scripts" directory for background tasks and DB ops.
    if [ -d "scripts" ]; then
      cp -r scripts/* src/ 2>/dev/null || true
    fi

    # Move any remaining top-level python files to src/
    mv *.py src/ 2>/dev/null || true
    for d in cwa_*; do
      if [ -d "$d" ]; then
        mv "$d" src/
      fi
    done

    # Fix Flask-Limiter v3.x compatibility
    sed -i -E 's/, ?auto_check=False//g' src/calibreweb/cps/__init__.py || true
    sed -i -E 's/, ?headers_enabled=True//g' src/calibreweb/cps/__init__.py || true

    # --- NEW: Fix Immutable Store & Docker Hardcoding ---
    # We dynamically route read-only Nix store paths and hardcoded Docker 
    # root paths (/config) safely into the Current Working Directory.
cat << 'EOF' > patch_paths.py
import re, glob
for filepath in glob.glob("src/**/*.py", recursive=True):
    with open(filepath, "r") as f: content = f.read()
    
    # 1. Reroute fallback databases to os.getcwd()
    cwd_inject = r"__import__('os').getcwd()"
    content = re.sub(r"os\.path\.dirname\(__file__\)(\s*,\s*['\"]app\.db['\"])", cwd_inject + r"\1", content)
    content = re.sub(r"os\.path\.dirname\(__file__\)(\s*,\s*['\"]gdrive\.db['\"])", cwd_inject + r"\1", content)
    content = re.sub(r"os\.path\.dirname\(__file__\)(\s*,\s*['\"]cwa\.db['\"])", cwd_inject + r"\1", content)
    
    # 2. Strip out Docker-specific root path assumptions
    content = content.replace("'/config'", "'.'")
    content = content.replace('"/config"', '"."')
    content = content.replace("'/config/", "'./")
    content = content.replace('"/config/', '"./')
    content = content.replace("'/cwa-book-ingest", "'./cwa-book-ingest")
    content = content.replace('"/cwa-book-ingest', '"./cwa-book-ingest')

    # 3. Force thumbnails and migrations to the writable working directory
    content = re.sub(r"os\.path\.join\([^)]*?['\"]thumbnails['\"]\s*\)", r"__import__('os').path.join(__import__('os').getcwd(), 'thumbnails')", content)
    content = re.sub(r"os\.path\.join\([^)]*?['\"].cwa_migrations['\"]\s*\)", r"__import__('os').path.join(__import__('os').getcwd(), '.cwa_migrations')", content)
    
    with open(filepath, "w") as f: f.write(content)
EOF
    python3 patch_paths.py
    rm patch_paths.py
    # --------------------------------------------------

    # Cleanly update pyproject.toml to discover ALL packages and modules in src/
    python3 -c '
import os
modules = [f[:-3] for f in os.listdir("src") if os.path.isfile(os.path.join("src", f)) and f.endswith(".py") and f != "setup.py"]
modules_str = ", ".join(f"\"{m}\"" for m in modules)
with open("pyproject.toml", "r") as f: content = f.read()
replace_with = f"[tool.setuptools]\npackage-dir = {{\"\" = \"src\"}}\npy-modules = [{modules_str}]\n"
content = content.replace("[tool.setuptools]", replace_with)
content += "\n\n[tool.setuptools.packages.find]\nwhere = [\"src\"]\n"
with open("pyproject.toml", "w") as f: f.write(content)
'
    substituteInPlace pyproject.toml \
      --replace-fail 'cps = "calibreweb:main"' 'calibre-web-automated = "calibreweb:main"' || true
  '';

  # Ensure the Python builder can find the src folder during the build phase
  preBuild = ''
    export PYTHONPATH=$PWD/src:$PYTHONPATH
  '';

  build-system = [ python3Packages.setuptools ];

  dependencies = with python3Packages; [
    apscheduler
    babel
    bleach
    chardet
    charset-normalizer # Added for CWA
    cryptography
    flask
    flask-babel
    flask-httpauth
    flask-limiter
    flask-principal
    flask-wtf
    idna               # Added for CWA
    iso-639
    lxml
    netifaces-plus
    polib              # Added for CWA
    pycountry
    pypdf
    python-magic
    pytz
    qrcode             # Added for CWA
    regex
    requests
    sqlalchemy
    tabulate           # Added for CWA
    tornado
    unidecode
    urllib3
    wand
  ];

  optional-dependencies = {
    comics = with python3Packages; [
      comicapi
      natsort
    ];

    gdrive = with python3Packages; [
      gevent
      google-api-python-client
      greenlet
      httplib2
      oauth2client
      pyasn1-modules
      # pydrive2
      pyyaml
      rsa
      uritemplate
    ];

    gmail = with python3Packages; [
      google-api-python-client
      google-auth-oauthlib
    ];

    kobo = with python3Packages; [ jsonschema ];

    ldap = with python3Packages; [
      flask-simpleldap
      python-ldap
    ];

    metadata = with python3Packages; [
      faust-cchardet
      html2text
      markdown2
      mutagen
      py7zr
      pycountry
      python-dateutil
      rarfile
      scholarly
    ];

    oauth = with python3Packages; [
      flask-dance
      sqlalchemy-utils
    ];
  };

  # Relax bounds so Nix doesn't complain about exact version mismatches
  pythonRelaxDeps = [
    "apscheduler"
    "bleach"
    "cryptography"
    "flask"
    "flask-limiter"
    "lxml"
    "pypdf"
    "regex"
    "requests"
    "tornado"
    "unidecode"
    "wand"
    "qrcode"
    "tabulate"
    "polib"
    "pycountry"
  ];

  nativeCheckInputs = lib.concatAttrValues optional-dependencies;

  pythonImportsCheck = [ "calibreweb" ];

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Calibre-Web but Automated and with tons of New Features! Fully automate and simplify your eBook set up!";
    homepage = "https://github.com/crocodilestick/Calibre-Web-Automated";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ];
    mainProgram = "calibre-web-automated";
    platforms = lib.platforms.all;
  };
}
