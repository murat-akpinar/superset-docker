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

# Geckodriver'ın PATH'e eklenmesi
ENV PATH="/usr/bin:$PATH"

# Python bağımlılıklarını yükleyin
RUN pip install --no-cache-dir gevent psycopg2 redis

USER superset
