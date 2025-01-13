- Secret key oluşturmak için
```bash
# Python komutundan üretilen değeri bir değişkene atayın
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

# sed komutunda bu değişkeni kullanın
sed -i "s/SUPERSET_CHANGE_SECRET_KEY/${SECRET_KEY}/g" docker-compose.yml superset_config.py

# Kontrol için SECRET_KEY değerini yazdırabilirsiniz
echo "Generated SECRET_KEY: ${SECRET_KEY}"

```
- Kullanıcı oluşturmak
docker-compose.yml dosyasında ki bu bölümü değiştirmeyi unutmayın. Burada oluşacak kullanıcı bilgilerini giriyoruz
```bash
superset fab create-admin --username admin --firstname Superset --lastname Admin --email murat.akpinar@muratakpinar.com.tr --password admin &&
```
- Mail ayarları
`superset_config.py` dosyasında ki mail bölümünü düzenlemeyi unutmayın.
```python3
# Email configuration
EMAIL_NOTIFICATIONS = True
SMTP_HOST = "smtp.office365.com"
SMTP_PORT = 587
SMTP_STARTTLS = True
SMTP_SSL_SERVER_AUTH = True
SMTP_SSL = False
SMTP_USER = "MAIL_USER"
SMTP_PASSWORD = "MAIL_PW*"
SMTP_MAIL_FROM = "MAUL_USER"
EMAIL_REPORTS_SUBJECT_PREFIX = "[Superset] "
```

- Docker build alma
```bash
docker build -t superset_firefox .
```
