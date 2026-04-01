import os

from celery.schedules import crontab

# Veritabanı URI
SUPERSET_DATABASE_URI = "sqlite:////app/superset_home/superset.db"

# docker-compose .env içindeki SUPERSET_SECRET_KEY (konteyner ortamı)
SUPERSET_SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY", "SUPERSET_CHANGE_SECRET_KEY")

# Feature flags
FEATURE_FLAGS = {
    "ALERT_REPORTS": True,
    "ALERT_REPORTS_NOTIFICATION_DRY_RUN": False,
}

# Redis configuration
REDIS_HOST = "redis"
REDIS_PORT = "6379"

# Celery configuration
class CeleryConfig:
    result_backend = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"
    broker_url = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"
    imports = (
        "superset.sql_lab",
        "superset.tasks.scheduler",
    )
    beat_schedule = {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
        "reports.prune_log": {
            "task": "reports.prune_log",
            "schedule": crontab(minute=0, hour=0),
        },
    }
    worker_prefetch_multiplier = 10
    task_acks_late = True
    task_annotations = {
        "sql_lab.get_sql_results": {
            "rate_limit": "100/s",
        },
    }

# Celery yapılandırması
CELERY_CONFIG = CeleryConfig

# Screenshot configuration
SCREENSHOT_LOCATE_WAIT = 100
SCREENSHOT_LOAD_WAIT = 600

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

# WebDriver configuration
WEBDRIVER_PATH = "/usr/bin/geckodriver"
WEBDRIVER_TYPE = "firefox"
WEBDRIVER_OPTION_ARGS = [
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    "--disable-extensions",
    "--disable-dev-shm-usage",
]
WEBDRIVER_BASEURL = "http://superset_app:8088"
WEBDRIVER_BASEURL_USER_FRIENDLY = "http://localhost:8088"
WEBDRIVER_WINDOW = {
    "slice": (1280, 1024),
    "dashboard": (1920, 1080),
}
SCREENSHOT_LOCATE_WAIT = 100
SCREENSHOT_LOAD_WAIT = 600

# WebDriver connection settings
WEBDRIVER_BASEURL = "http://superset_app:8088"
WEBDRIVER_BASEURL_USER_FRIENDLY = "http://localhost:8088"
