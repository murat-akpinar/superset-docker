FROM apache/superset:latest
USER root
RUN apt update && \
    apt-get install --no-install-recommends -y \
    firefox-esr wget tar build-essential libpq-dev gcc sqlite3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV GECKODRIVER_VERSION=0.32.2
RUN wget -q https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz && \
    tar -xvzf geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz -C /usr/bin && \
    chmod 755 /usr/bin/geckodriver && \
    rm geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz

RUN if [ -x /app/docker/pip-install.sh ]; then \
      /app/docker/pip-install.sh \
        gevent psycopg2-binary redis \
        pymssql cx_Oracle \
        pillow reportlab Flask-Mail flask pandas requests selenium; \
    else \
      python -m pip install --no-cache-dir \
        gevent psycopg2-binary redis \
        pymssql cx_Oracle \
        pillow reportlab Flask-Mail flask pandas requests selenium; \
    fi

ARG USER_ID=1000
ARG GROUP_ID=1000
RUN OLD_UID=$(id -u superset) && OLD_GID=$(id -g superset) && \
    groupmod -g "${GROUP_ID}" superset && \
    usermod -u "${USER_ID}" -g "${GROUP_ID}" superset && \
    find /app /home/superset \( -uid "${OLD_UID}" -o -gid "${OLD_GID}" \) -exec chown "${USER_ID}:${GROUP_ID}" {} + 2>/dev/null || true

USER superset
