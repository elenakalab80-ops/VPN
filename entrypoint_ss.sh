#!/bin/sh
set -e

CONFIG_DIR="/etc/shadowsocks"
mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_DIR/password" ]; then
  PASSWORD=$(cat "$CONFIG_DIR/password")
else
  PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)
  echo "$PASSWORD" > "$CONFIG_DIR/password"
fi

METHOD="chacha20-ietf-poly1305"
PORT=8388

# Hostname for SIP002 link: Fly injects FLY_APP_NAME; optional override for tests.
if [ -n "$SS_HOST" ]; then
  HOST="$SS_HOST"
elif [ -n "$FLY_APP_NAME" ]; then
  HOST="${FLY_APP_NAME}.fly.dev"
else
  HOST="127.0.0.1"
fi

# SIP002: обычно base64(method:password) с padding (без переносов строк).
CREDENTIALS_STD=$(printf '%s' "${METHOD}:${PASSWORD}" | base64 | tr -d '\n')
# Некоторые клиенты принимают URL-safe base64 без padding — дублируем для проверки.
CREDENTIALS_URL=$(printf '%s' "${METHOD}:${PASSWORD}" | base64 | tr -d '\n=' | tr '+/' '-_')
SS_LINK="ss://${CREDENTIALS_STD}@${HOST}:${PORT}#Fly-Shadowsocks"
SS_LINK_ALT="ss://${CREDENTIALS_URL}@${HOST}:${PORT}#Fly-Shadowsocks"

echo ""
echo "========================================================"
echo "              SHADOWSOCKS (ssserver-rust)                "
echo "========================================================"
echo ""
echo "Server host: $HOST"
echo "Method:      $METHOD"
echo "Password:    $PASSWORD"
echo "Port:        $PORT"
echo ""
echo "ACCESS KEY (SIP002, сначала попробуйте эту строку в Outline):"
echo ""
echo "$SS_LINK"
echo ""
echo "Если не подключается — попробуйте альтернативную кодировку:"
echo "$SS_LINK_ALT"
echo ""
echo "Копируйте одну строку целиком, без пробела перед символом @."
echo ""
echo "========================================================"
echo ""

if command -v qrencode >/dev/null 2>&1; then
  echo "QR (terminal):"
  qrencode -t ansiutf8 "$SS_LINK" || true
  echo ""
fi

echo "Starting ssserver..."
exec ssserver -s "0.0.0.0:$PORT" -m "$METHOD" -k "$PASSWORD" -U --log-without-time
