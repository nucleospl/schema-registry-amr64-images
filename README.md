# schema-registry-amr64-images

Unofficial [Confluent Schema Registry](https://github.com/confluentinc/schema-registry) Docker images for `linux/amd64` and `linux/arm64`, built natively on dedicated GitHub Actions runners — no QEMU, no emulation.

Images are published to [GHCR](https://github.com/orgs/nucleospl/packages?repo_name=schema-registry-amr64-images) and signed with cosign (keyless OIDC). Each release also includes a Helm chart for installing Schema Registry on Kubernetes.

## Why this project?

Bitnami stopped publishing `bitnami/schema-registry` images. This project replaces them with images built directly from Confluent's source code, with native ARM64 support and a ready-to-use Helm chart.

## Automated releases

Releases are created **fully automatically**:

1. The `check-release.yml` workflow polls Docker Hub (`confluentinc/cp-schema-registry`) **every 6 hours**
2. When a new tag is detected (e.g. `8.3.0`), it resolves the matching branch and commit SHA in [confluentinc/schema-registry](https://github.com/confluentinc/schema-registry)
3. It triggers `build.yml`, which:
   - Builds `linux/amd64` on a native x86_64 runner and `linux/arm64` on a native ARM64 runner — in parallel
   - Scans both images with Trivy
   - Merges them into a single multi-arch manifest
   - Pushes to GHCR and signs with cosign
   - Packages and publishes the Helm chart to GHCR OCI
   - Creates a GitHub Release with the chart attached
   - Updates `versions.json`

The first build, or a manual rebuild of a specific version, can be triggered via **Actions → Build → Run workflow**.

## Usage

### Docker

```bash
docker pull ghcr.io/nucleospl/schema-registry-amr64-images/schema-registry:8.2.0
```

Required environment variables:

```bash
docker run --rm \
  -e SCHEMA_REGISTRY_HOST_NAME=localhost \
  -e SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS=PLAINTEXT://kafka:9092 \
  -e SCHEMA_REGISTRY_LISTENERS=http://0.0.0.0:8081 \
  -p 8081:8081 \
  ghcr.io/nucleospl/schema-registry-amr64-images/schema-registry:8.2.0
```

### Helm chart

```bash
helm install schema-registry \
  oci://ghcr.io/nucleospl/schema-registry-amr64-images/charts/schema-registry \
  --version 8.2.0 \
  --set kafka.bootstrapServers=PLAINTEXT://kafka:9092
```

Example `values.yaml`:

```yaml
image: ghcr.io/nucleospl/schema-registry-amr64-images/schema-registry
imageTag: "8.2.0"

kafka:
  bootstrapServers: "PLAINTEXT://kafka-headless:9092"

replicaCount: 1

resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    memory: 768Mi
```

Full list of options: [`charts/schema-registry/values.yaml`](charts/schema-registry/values.yaml).

### Signature verification (cosign)

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/nucleospl/schema-registry-amr64-images/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/nucleospl/schema-registry-amr64-images/schema-registry:8.2.0
```

## Version mapping

Image versions match the tags published by `confluentinc/cp-schema-registry` on Docker Hub. Each tag corresponds to a branch of the same name in [confluentinc/schema-registry](https://github.com/confluentinc/schema-registry).

| GHCR tag | Source branch |
|----------|---------------|
| `8.2.0` | [`8.2.0`](https://github.com/confluentinc/schema-registry/tree/8.2.0) |
| `8.1.2` | [`8.1.2`](https://github.com/confluentinc/schema-registry/tree/8.1.2) |

## License

Build tooling (Dockerfile, workflows, Helm chart): Apache 2.0.
Schema Registry itself: [Confluent Community License](https://github.com/confluentinc/schema-registry/blob/master/LICENSE-ConfluentCommunity).
