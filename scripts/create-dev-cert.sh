#!/usr/bin/env bash
# Creates a local self-signed code signing identity "NotchFill Dev" in the login keychain.
# With a stable identity, macOS keeps the Accessibility / Screen Recording permissions
# between builds. Use it with:  CODESIGN_IDENTITY="NotchFill Dev" ./scripts/build-app.sh
set -euo pipefail

NAME="${1:-NotchFill Dev}"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$NAME" "$KEYCHAIN" >/dev/null 2>&1; then
  echo "Identity \"$NAME\" exists already."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS="$(/usr/bin/openssl rand -hex 16)"

/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -subj "/CN=$NAME" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" \
  -addext "basicConstraints=critical,CA:false" \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" 2>/dev/null

/usr/bin/openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -name "$NAME" -out "$TMP/id.p12" -passout "pass:$PASS" 2>/dev/null

security import "$TMP/id.p12" -k "$KEYCHAIN" -P "$PASS" -T /usr/bin/codesign >/dev/null
echo "Created identity \"$NAME\" in the login keychain."
