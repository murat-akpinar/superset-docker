#!/usr/bin/env bash
# Stack sağlık kontrolü: Superset, Redis, Celery worker, Celery beat.
# Kullanım: ./healthcheck.sh   (docker-compose.yml ile aynı dizinde)
# Önce proje kökündeki .env okunur (docker compose ile aynı dosya); böylece REDIS_PASSWORD vb. export edilir.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Docker Compose .env benzeri: KEY=VALUE, # yorum, çift/tek tırnaklı değer. bash source kullanmıyoruz ($ genişlemesi olmasın diye).
load_env_file() {
  local f=${1:-.env}
  [[ -f "$f" ]] || return 0
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    key="${key#"${key%%[![:space:]]*}"}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    if [[ "$val" == \"*\" ]]; then
      val="${val#\"}"
      val="${val%\"}"
    elif [[ "$val" == \'*\' ]]; then
      val="${val#\'}"
      val="${val%\'}"
    fi
    export "${key}=${val}"
  done <"$f"
}

load_env_file .env
if [[ ! -f .env ]]; then
  echo "Uyarı: .env bulunamadı — Redis parolası için cp .env.example .env veya çalışan redis konteynerinden okunacak." >&2
fi

failures=0

ok()  { printf '[OK]   %s\n' "$*"; }
bad() { printf '[FAIL] %s\n' "$*" >&2; failures=$((failures + 1)); }

resolve_redis_password() {
  if [[ -n "${REDIS_PASSWORD+x}" && -n "$REDIS_PASSWORD" ]]; then
    printf '%s' "$REDIS_PASSWORD"
    return
  fi
  if docker inspect redis &>/dev/null; then
    local pw
    pw=$(docker inspect redis --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | sed -n 's/^REDIS_PASSWORD=//p' | head -1)
    if [[ -n "$pw" ]]; then
      printf '%s' "$pw"
      return
    fi
  fi
  if [[ -f .env ]]; then
    local line val
    line=$(grep -E '^[[:space:]]*REDIS_PASSWORD=' .env 2>/dev/null | tail -1 || true)
    if [[ -n "$line" ]]; then
      val="${line#*=}"
      val="${val%\"}"
      val="${val#\"}"
      val="${val%\'}"
      val="${val#\'}"
      printf '%s' "$val"
      return
    fi
  fi
  printf '%s' ''
}

container_running() {
  local name=$1
  [[ "$(docker inspect "$name" --format '{{.State.Running}}' 2>/dev/null)" == "true" ]]
}

echo "=== Docker stack healthcheck ($(date -Iseconds 2>/dev/null || date)) ==="
echo

for c in redis superset_app celery_worker celery_beat; do
  if container_running "$c"; then
    ok "Konteyner çalışıyor: $c"
  else
    bad "Konteyner çalışmıyor veya yok: $c"
  fi
done

echo
REDIS_PW="$(resolve_redis_password)"

if container_running redis; then
  if [[ -z "$REDIS_PW" ]]; then
    bad "REDIS_PASSWORD boş — proje kökünde .env içine REDIS_PASSWORD=... ekleyin veya export edin"
  elif docker exec redis redis-cli -a "$REDIS_PW" ping 2>/dev/null | grep -q PONG; then
    ok "Redis PING (AUTH)"
  else
    bad "Redis PING başarısız (yanlış parola veya Redis yanıt vermiyor)"
  fi
else
  bad "Redis konteyneri yok; PING atlandı"
fi

echo
if container_running superset_app; then
  if curl -sfS --max-time 10 http://127.0.0.1:8088/health >/dev/null 2>&1; then
    ok "Superset HTTP /health (localhost:8088)"
  elif docker exec superset_app wget -q -O- --timeout=10 http://127.0.0.1:8088/health >/dev/null 2>&1; then
    ok "Superset HTTP /health (konteyner içi wget)"
  else
    bad "Superset /health yanıt vermiyor"
  fi
else
  bad "superset_app yok; /health atlandı"
fi

echo
if container_running celery_worker; then
  if docker exec celery_worker celery --app=superset.tasks.celery_app:app inspect ping -t 15 >/dev/null 2>&1; then
    ok "Celery worker inspect ping"
  else
    bad "Celery worker inspect ping başarısız (broker/queue/konfigürasyon)"
  fi
else
  bad "celery_worker yok; ping atlandı"
fi

echo
if container_running celery_beat; then
  if docker exec celery_beat sh -c 'test -f /tmp/celerybeat.pid && kill -0 "$(cat /tmp/celerybeat.pid)"' 2>/dev/null; then
    ok "Celery beat pidfile süreci yaşıyor"
  else
    bad "Celery beat pidfile yok veya süreç ölü"
  fi
else
  bad "celery_beat yok; beat atlandı"
fi

echo
if [[ "$failures" -eq 0 ]]; then
  echo "Sonuç: tüm kontroller geçti."
  exit 0
fi

echo "Sonuç: $failures kontrol başarısız."
exit 1
