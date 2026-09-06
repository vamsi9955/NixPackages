{ pkgs, python3, fetchFromGitHub }:

let
  python = python3;
  
  django-health-check = python.pkgs.buildPythonPackage {
    pname = "django-health-check";
    version = "4.2.2";
    src = pkgs.fetchPypi {
      pname = "django_health_check";
      version = "4.2.2";
      hash = "sha256-ZvmGG+HFNgf9JgN+uMna5Y24wj40rweSvG+dePKPpkw=";
    };
    pyproject = true;
    build-system = [ python.pkgs.flit-core python.pkgs.flit-scm ];
    env.SETUPTOOLS_SCM_PRETEND_VERSION = "4.2.2";
    dependencies = [ python.pkgs.django python.pkgs.dnspython ];
    doCheck = false;
  };

  django-select2 = python.pkgs.buildPythonPackage {
    pname = "django-select2";
    version = "8.4.8";
    src = pkgs.fetchPypi {
      pname = "django_select2";
      version = "8.4.8";
      hash = "sha256-WS5S7//ytYUMt8mLJlcVtnBPt4RpnErt3f3Yrh/6HoE=";
    };
    pyproject = true;
    build-system = [ python.pkgs.flit-core python.pkgs.flit-scm ];
    env.SETUPTOOLS_SCM_PRETEND_VERSION = "8.4.8";
    dependencies = [ python.pkgs.django python.pkgs.django-appconf ];
    doCheck = false;
  };

  django-decorator-include = python.pkgs.buildPythonPackage {
    pname = "django-decorator-include";
    version = "3.3";
    src = pkgs.fetchPypi {
      pname = "django_decorator_include";
      version = "3.3";
      hash = "sha256-M29zxAOYOl0b9NpfGc0RTbOpErm/wOae8fIM5YmCjD4=";
    };
    pyproject = true;
    build-system = [ python.pkgs.flit-core python.pkgs.flit-scm ];
    env.SETUPTOOLS_SCM_PRETEND_VERSION = "3.3";
    dependencies = [ python.pkgs.django python.pkgs.django-appconf ];
    doCheck = false;
  };

  # Use requests-ratelimiter v1.x which supports pyrate-limiter v4.x
  requests-ratelimiter = python.pkgs.buildPythonPackage {
    pname = "requests-ratelimiter";
    version = "1.0.1";
    src = pkgs.fetchPypi {
      pname = "requests_ratelimiter";
      version = "1.0.1";
      hash = "sha256-r0wr5/SRcxq5oOGg4v4/W1L8H3F3i4RZ7nJqH5jH5Y8=";
    };
    pyproject = true;
    build-system = [ python.pkgs.hatchling ];
    dependencies = [
      python.pkgs.pyrate-limiter
      python.pkgs.requests
    ];
    doCheck = false;
  };

  yamtrackDeps = with python.pkgs; [
    aiohttp apprise beautifulsoup4 celery croniter defusedxml django
    django-allauth django-celery-beat django-celery-results django-debug-toolbar
    django-decorator-include django-health-check django-model-utils django-redis django-select2
    django-simple-history django-widget-tweaks gunicorn hiredis icalendar
    pillow psycopg python-decouple redis requests requests-ratelimiter
    unidecode
  ];

in python.pkgs.buildPythonPackage {
  pname = "yamtrack";
  version = "main";
  
  # Fetches the actual python code from GitHub
  src = fetchFromGitHub {
    owner = "FuzzyGrim";
    repo = "Yamtrack";
    rev = "master";
    hash = "sha256-0hJA6YDE+e4xkCjP5Sh4HxioufEOrOy/ZxjgQeDAS+o="; 
  };

  pyproject = false;

  postPatch = ''
    substituteInPlace src/config/settings.py \
      --replace-fail \
        'Path(BASE_DIR / "db").mkdir(parents=True, exist_ok=True)' \
        '(Path(BASE_DIR / "db").mkdir(parents=True, exist_ok=True) if not str(BASE_DIR).startswith("/nix/store") else None)'

    substituteInPlace src/config/settings.py \
      --replace-fail \
        '"NAME": BASE_DIR / "db" / "db.sqlite3",' \
        '"NAME": config("DB_PATH", default=str(BASE_DIR / "db" / "db.sqlite3")),'

    substituteInPlace src/config/test_settings.py \
      --replace-fail 'FakeRedisConnection' 'FakeConnection'
  '';

  propagatedBuildInputs = yamtrackDeps;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  buildPhase = ''
    runHook preBuild
    export DJANGO_SETTINGS_MODULE=config.settings
    export SECRET=build-secret-not-real
    cd src
    ${python.pythonOnBuildForHost.interpreter} manage.py collectstatic --noinput
    cd ..
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/yamtrack
    cp -r src/. $out/lib/yamtrack/
    chmod +x $out/lib/yamtrack/manage.py
    makeWrapper $out/lib/yamtrack/manage.py $out/bin/yamtrack-manage \
      --prefix PYTHONPATH : "$PYTHONPATH"
    runHook postInstall
  '';

  passthru = {
    pythonEnv = python.withPackages (_: yamtrackDeps);
  };

  doCheck = false;
}
