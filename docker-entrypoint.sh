#!/bin/bash
# Entrypoint dla Schema Registry ARM64.
# Konwertuje zmienne środowiskowe SCHEMA_REGISTRY_* na plik properties i uruchamia serwer.
#
# Konwencja mapowania (identyczna z oficjalnymi obrazami Confluent):
#   SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS → kafkastore.bootstrap.servers
#   SCHEMA_REGISTRY_HOST_NAME                    → host.name
#   SCHEMA_REGISTRY_LISTENERS                    → listeners
#
# Wymagane zmienne:
#   SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS  — adresy brokerów Kafka
#   SCHEMA_REGISTRY_HOST_NAME                     — hostname/IP poda (w K8s: status.podIP)

set -euo pipefail

CONF_FILE="${SCHEMA_REGISTRY_CONF_FILE:-/tmp/schema-registry.properties}"

# Generowanie pliku konfiguracyjnego ze zmiennych środowiskowych
{
  for var in $(printenv | grep '^SCHEMA_REGISTRY_' | cut -d= -f1 | sort); do
    value="${!var}"
    # Usuń prefiks SCHEMA_REGISTRY_, zamień na lowercase, podkreślenia → kropki
    prop_key=$(printf '%s' "${var#SCHEMA_REGISTRY_}" | tr '[:upper:]' '[:lower:]' | tr '_' '.')
    printf '%s=%s\n' "$prop_key" "$value"
  done
} > "$CONF_FILE"

# Weryfikacja wymaganych właściwości
if ! grep -q '^host\.name=' "$CONF_FILE"; then
  echo "BŁĄD: SCHEMA_REGISTRY_HOST_NAME nie jest ustawiony." >&2
  exit 1
fi

if ! grep -qE '^kafkastore\.(bootstrap\.servers|connection\.url)=' "$CONF_FILE"; then
  echo "BŁĄD: Ustaw SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS (lub SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL)." >&2
  exit 1
fi

echo "==> Konfiguracja Schema Registry wygenerowana: $CONF_FILE"
echo "==> Uruchamianie Schema Registry..."

exec "${SCHEMA_REGISTRY_HOME}/bin/schema-registry-start" "$CONF_FILE"
