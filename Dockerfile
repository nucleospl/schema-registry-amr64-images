# Etap 1: Budowanie binarek z kodu źródłowego Confluent Schema Registry
# Używamy oficjalnego obrazu maven:3.9 — protobuf-maven-plugin wymaga Maven ≥ 3.8,
# a apt-get install maven na Ubuntu Jammy daje tylko 3.6.3.
FROM maven:3.9-eclipse-temurin-17 AS builder

ARG SCHEMA_REGISTRY_SHA
WORKDIR /build

# Instalacja Git (Maven i JDK już są w obrazie bazowym)
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
    && rm -rf /var/lib/apt/lists/*

# Klonowanie i weryfikacja SHA (odporność na tag-tampering)
RUN git clone --filter=blob:none https://github.com/confluentinc/schema-registry.git . && \
    git checkout "$SCHEMA_REGISTRY_SHA" && \
    ACTUAL=$(git rev-parse HEAD) && \
    if [ "$ACTUAL" != "$SCHEMA_REGISTRY_SHA" ]; then \
      echo "::error::SHA mismatch! expected=$SCHEMA_REGISTRY_SHA actual=$ACTUAL" && exit 1; \
    fi && \
    echo "Upstream verified at SHA: $ACTUAL"

# Budowanie dystrybucji — tylko moduł package-schema-registry i jego zależności
# Confluent public Maven repo (packages.confluent.io/maven) jest dostępne publicznie
RUN --mount=type=cache,target=/root/.m2 \
    mvn package -DskipTests \
        -pl package-schema-registry -am \
        --no-transfer-progress \
        -Dmaven.test.skip=true \
        -Dcheckstyle.skip=true \
        -Dspotbugs.skip=true

# Przenieś dystrybucję do stałej ścieżki (bez wersji w nazwie katalogu)
RUN mkdir -p /dist && \
    cp -a package-schema-registry/target/kafka-schema-registry-package-*-package/. /dist/


# Etap 2: Obraz runtime — minimalna JRE na ARM64
FROM eclipse-temurin:17-jre-jammy

ARG SCHEMA_REGISTRY_VERSION
ARG SCHEMA_REGISTRY_SHA

LABEL org.opencontainers.image.title="Schema Registry ARM64" \
      org.opencontainers.image.description="Confluent Schema Registry zbudowany natywnie dla linux/arm64" \
      org.opencontainers.image.version="${SCHEMA_REGISTRY_VERSION}" \
      org.opencontainers.image.revision="${SCHEMA_REGISTRY_SHA}" \
      org.opencontainers.image.source="https://github.com/nucleospl/schema-registry-arm64-images" \
      org.opencontainers.image.licenses="Apache-2.0" \
      io.confluent.schema-registry.version="${SCHEMA_REGISTRY_VERSION}"

ENV SCHEMA_REGISTRY_HOME=/opt/schema-registry
ENV PATH="$SCHEMA_REGISTRY_HOME/bin:$PATH"
ENV LOG_DIR=/var/log/schema-registry

# Tworzenie użytkownika nieprivilegowanego i katalogów
RUN groupadd --gid 10001 schema-registry && \
    useradd --uid 10001 --gid schema-registry --no-create-home --shell /bin/false schema-registry && \
    mkdir -p "$SCHEMA_REGISTRY_HOME" "$LOG_DIR" /etc/schema-registry && \
    chown schema-registry:schema-registry "$LOG_DIR" /etc/schema-registry

# Kopiowanie dystrybucji z etapu builder
COPY --from=builder --chown=schema-registry:schema-registry /dist/ $SCHEMA_REGISTRY_HOME/

# Entrypoint — konwertuje SCHEMA_REGISTRY_* env vars do pliku properties
COPY --chown=root:root docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Schema Registry nasłuchuje na 8081
EXPOSE 8081

USER schema-registry

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
