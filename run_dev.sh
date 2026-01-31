#!/usr/bin/env bash

# run_dev.sh
# Boots the FastAPI backend plus a selected Flutter platform with the right defines.
# Exists so devs can run the full stack locally with one command.
# RELEVANT FILES:backend/app/main.py,backend/.env,lib/app/core/config/app_config.dart,lib/main.dart

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Always prefer the repo-local venv so copied folders don't accidentally keep using
# an old venv from another path (which leads to missing deps at runtime).
PYTHON_BIN="$ROOT_DIR/.venv/bin/python"
if [[ ! -x "$PYTHON_BIN" ]]; then
  PYTHON_BIN="python3"
fi

### ==========================
### CONFIGURARE GLOBALĂ
### ==========================

SUPABASE_URL="https://icogpatyypsirbrjryzb.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imljb2dwYXR5eXBzaXJicmpyeXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI2MjQ0MTYsImV4cCI6MjA3ODIwMDQxNn0.uYTsB-EMzZFzX_JikDVF7X8HJleBFHf-wuZnyje5cyw"

BACKEND_DIR="backend"
BACKEND_APP="app.main:app"

resolve_host_ip() {
  local interfaces=("en0" "en1")
  for iface in "${interfaces[@]}"; do
    local ip
    ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return
    fi
  done
  echo ""
}

### ==========================
### PORNIRE BACKEND
### ==========================

cleanup() {
  if [[ -n "$BACKEND_PID" ]]; then
    echo "=== Oprire backend (PID $BACKEND_PID) ==="
    kill "$BACKEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "=== Verific portul backend (8000) ==="
EXISTING_BACKEND_PIDS=$(lsof -ti tcp:8000 2>/dev/null || true)
if [[ -n "$EXISTING_BACKEND_PIDS" ]]; then
  echo "=== Găsit backend deja pornit pe 8000. Îl opresc... ==="
  echo "$EXISTING_BACKEND_PIDS" | xargs kill -9 2>/dev/null || true
  sleep 1
fi

echo "=== Pornesc backend (FastAPI + DeepSeek) ==="
cd "$BACKEND_DIR"
$PYTHON_BIN -m uvicorn $BACKEND_APP --reload --host 0.0.0.0 &
BACKEND_PID=$!
cd ..

LOCAL_HOST_IP=$(resolve_host_ip)
if [[ -n "$LOCAL_HOST_IP" ]]; then
  echo "=== IP local detectat: $LOCAL_HOST_IP ==="
else
  echo "=== Nu am găsit adresa IP Wi-Fi. Folosesc localhost. ==="
  LOCAL_HOST_IP="127.0.0.1"
fi
IOS_DEVICE_API_BASE="http://$LOCAL_HOST_IP:8000"


### ==========================
### MENIU SELECTARE PLATFORMĂ
### ==========================

echo ""
echo "Selectează platforma:"
echo "1) Android"
echo "2) iOS"
echo "3) Web"
echo "4) Desktop"
echo "5) iOS (release)"
echo ""
read -p "Alege (1-5): " PLATFORM

### ==========================
### RULARE FLUTTER ÎN FUNCȚIE DE PLATFORMĂ
### ==========================

case $PLATFORM in

  1)
    echo "=== Pornesc Flutter pe Android ==="
    flutter run \
      --dart-define=SUPABASE_URL=$SUPABASE_URL \
      --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
      --dart-define=API_BASE_URL=http://10.0.2.2:8000
    ;;

  2)
    echo "=== Pornesc Flutter pe iOS ==="
    flutter run \
      --dart-define=SUPABASE_URL=$SUPABASE_URL \
      --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
      --dart-define=API_BASE_URL=$IOS_DEVICE_API_BASE
    ;;

  3)
    echo "=== Pornesc Flutter pe Web (Chrome) ==="
    flutter run -d chrome \
      --web-renderer=html \
      --dart-define=SUPABASE_URL=$SUPABASE_URL \
      --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
      --dart-define=API_BASE_URL=http://localhost:8000
    ;;

  4)
    echo "=== Pornesc Flutter pe Desktop ==="
    flutter run \
      --dart-define=SUPABASE_URL=$SUPABASE_URL \
      --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
      --dart-define=API_BASE_URL=http://localhost:8000
    ;;

  5)
    echo "=== Pornesc Flutter pe iOS (release) ==="
    flutter run --release \
      --dart-define=SUPABASE_URL=$SUPABASE_URL \
      --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
      --dart-define=API_BASE_URL=$IOS_DEVICE_API_BASE
    ;;

  *)
    echo "Opțiune invalidă!"
    ;;

esac

### ==========================
### OPRIRE BACKEND DUPĂ Flutter
### ==========================

echo "=== Tot stack-ul s-a oprit. ==="
