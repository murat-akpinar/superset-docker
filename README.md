# Apache Superset (Docker Compose)

Apache Superset için Docker Compose kurulumu: Firefox + Geckodriver ile rapor ekran görüntüsü, Celery worker/beat, Redis (kimlik doğrulamalı), SQLite veri dizini.

## Gereksinimler

- Docker ve Docker Compose (v2)

## İlk kurulum

1. Ortam dosyası: **Redis parolası** ve **Superset secret** ayrı ayrı üretilir; her `sed` yalnızca kendi satırını (`^REDIS_PASSWORD=` / `^SUPERSET_SECRET_KEY=`) değiştirir. Linux `sed -i`; macOS `sed -i ''`.

   ```bash
   REDIS_PASSWORD=$(python3 -c "import secrets; print(secrets.token_urlsafe(24))")
   SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
   sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=${REDIS_PASSWORD}/" .env.example
   sed -i "s/^SUPERSET_SECRET_KEY=.*/SUPERSET_SECRET_KEY=${SECRET_KEY}/" .env.example
   mv .env.example .env
   echo "Generated REDIS_PASSWORD: ${REDIS_PASSWORD}"
   echo "Generated SUPERSET_SECRET_KEY: ${SECRET_KEY}"
   ```

   `s/CHANGE_ME/.../g` gibi **tüm dosyada** değiştiren sed kullanmayın.

   `mv` şablonu çalışma dizininden kaldırır; gerekirse `git checkout -- .env.example`. Alternatif: `cp .env.example .env` ve her iki `sed` satırını `.env` üzerinde çalıştırın.

   `.env` repoya eklenmez (`.gitignore`). `docker-compose.yml` / `superset_config.py` içinde bu sırlar için `sed` kullanmayın.

2. (İsteğe bağlı) Bind mount izinleri için image build sırasında host kullanıcısı ile UID/GID eşleştirmek:

   ```bash
   export USER_ID=$(id -u) GROUP_ID=$(id -g)
   ```

## Çalıştırma

```bash
docker compose build
docker compose up -d
```

Uygulama: [http://localhost:8088](http://localhost:8088)

İlk admin kullanıcısı `docker-compose.yml` içindeki `superset fab create-admin ...` satırından oluşturulur; e-posta, kullanıcı adı ve parolayı oradan kendi ortamınıza göre düzenleyin.

## Sağlık kontrolü

Proje kökündeki `.env` ile aynı değerleri kullanır (özellikle `REDIS_PASSWORD`):

```bash
chmod +x healthcheck.sh
./healthcheck.sh
```

Tüm kontroller geçerse çıkış kodu `0`dır.

## Yapılandırma notları

### Gizli anahtar ve Redis

- `SUPERSET_SECRET_KEY` ve `REDIS_PASSWORD` yalnızca **`.env`** üzerinden verilir; `docker-compose.yml` içinde sabit tutulmaz.
- Eski yöntem olan `sed -i "s/SUPERSET_CHANGE_SECRET_KEY/.../g" docker-compose.yml superset_config.py` **kullanılmaz**; gizli anahtar sadece `.env` içindeki `SUPERSET_SECRET_KEY` ile yönetilir.
- `superset_config.py` içinde `SUPERSET_SECRET_KEY`, konteyner ortamından (`os.getenv`) okunur; Compose bu değeri `.env`’den aktarır.

### E-posta (rapor / bildirim)

`superset_config.py` dosyasındaki SMTP alanlarını düzenleyin:

```python
EMAIL_NOTIFICATIONS = True
SMTP_HOST = "smtp.office365.com"
SMTP_PORT = 587
SMTP_STARTTLS = True
SMTP_SSL_SERVER_AUTH = True
SMTP_SSL = False
SMTP_USER = "MAIL_USER"
SMTP_PASSWORD = "MAIL_PW*"
SMTP_MAIL_FROM = "MAIL_USER"
EMAIL_REPORTS_SUBJECT_PREFIX = "[Superset] "
```

### Alert ve Report

Rapor/alert özelliğini kapatmak için `docker-compose.yml` içinde:

```yaml
FEATURE_FLAGS_ALERT_REPORTS: "false"
```

## Sadece imaj derleme

Compose ile (UID/GID build arg’ları için tercih edilen yol):

```bash
docker compose build
```

Doğrudan Dockerfile:

```bash
docker build -t superset_firefox .
```
