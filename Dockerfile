FROM apache/superset:latest

USER root

# Gerekli sistem araçlarını yükleyin
RUN apt update && \
    apt-get install --no-install-recommends -y \
    firefox-esr wget tar build-essential libpq-dev gcc sqlite3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Geckodriver'ı yükleyin
ENV GECKODRIVER_VERSION=0.32.2
RUN wget -q https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz && \
    tar -xvzf geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz -C /usr/bin && \
    chmod 755 /usr/bin/geckodriver && \
    rm geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz

# PATH'e dokunma: apache/superset imajı superset/celery için /app/.venv/bin kullanıyor; sabit PATH onu siliyordu.
# Geckodriver /usr/bin'de; bu dizin üst imajın PATH'inde zaten var.

# Python bağımlılıklarını root ile kurun (runtime'da superset kullanıcısı site-packages'a yazamaz)
RUN pip install --no-cache-dir \
    gevent psycopg2 redis \
    pymssql cx_Oracle \
    pillow reportlab Flask-Mail flask pandas requests selenium

# Bind mount dizinleri host kullanıcısı ile aynı UID/GID görsün (Linux/WSL). Varsayılan 1000:1000.
# Build: USER_ID=$(id -u) GROUP_ID=$(id -g) docker compose build  veya .env içinde USER_ID/GROUP_ID
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN OLD_UID=$(id -u superset) && OLD_GID=$(id -g superset) && \
    groupmod -g "${GROUP_ID}" superset && \
    usermod -u "${USER_ID}" -g "${GROUP_ID}" superset && \
    find /app /home/superset \( -uid "${OLD_UID}" -o -gid "${OLD_GID}" \) -exec chown "${USER_ID}:${GROUP_ID}" {} + 2>/dev/null || true

USER superset
