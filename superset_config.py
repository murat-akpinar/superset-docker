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

# Timeout settings
SQLLAB_TIMEOUT = 300
SUPERSET_WEBSERVER_TIMEOUT = 300

# Row limit settings
ROW_LIMIT = 500000
SQL_MAX_ROW = 500000
DISPLAY_MAX_ROW = 500000

# Redis configuration
REDIS_HOST = "redis"
REDIS_PORT = 6379
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", "")


def _redis_uri(db: int) -> str:
    auth = f":{REDIS_PASSWORD}@" if REDIS_PASSWORD else ""
    return f"redis://{auth}{REDIS_HOST}:{REDIS_PORT}/{db}"

# Celery configuration
class CeleryConfig:
    result_backend = _redis_uri(0)
    broker_url = _redis_uri(0)
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

# Cache configuration
FILTER_STATE_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 86400,
    "CACHE_KEY_PREFIX": "superset_filter_",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_PASSWORD": REDIS_PASSWORD,
    "CACHE_REDIS_DB": 1,
}

EXPLORE_FORM_DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 86400,
    "CACHE_KEY_PREFIX": "superset_explore_",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_PASSWORD": REDIS_PASSWORD,
    "CACHE_REDIS_DB": 1,
}

DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_data_",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_PASSWORD": REDIS_PASSWORD,
    "CACHE_REDIS_DB": 2,
}

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
SMTP_MAIL_FROM = "MAIL_USER"
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
