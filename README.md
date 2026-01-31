# Fluentd Kube Elastic

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/btungut)](https://artifacthub.io/packages/helm/btungut/fluentd-kube-elastic)
[![Release](https://img.shields.io/github/v/release/btungut/fluentd-kube-elastic?include_prereleases&style=plastic)](https://github.com/btungut/fluentd-kube-elastic/releases)
[![LICENSE](https://img.shields.io/github/license/btungut/fluentd-kube-elastic?style=plastic)](https://github.com/btungut/fluentd-kube-elastic/blob/master/LICENSE)

A production-ready Fluentd implementation for collecting, parsing, and shipping Kubernetes container logs to Elasticsearch. Automatically handles both **plain-text** and **JSON** formatted logs with intelligent parsing.

## Features

- **Automatic Log Format Detection** - Seamlessly handles both plain-text and JSON logs
- **Multiline Log Support** - Properly aggregates stack traces and multiline log entries
- **Namespace Filtering** - Collect logs only from specific namespaces using regex patterns
- **Label-based Filtering** - Filter logs based on Kubernetes pod labels
- **Noise Reduction** - Exclude health checks, probes, and unwanted log patterns
- **Prometheus Metrics** - Built-in observability with metrics by namespace and container image
- **TLS Support** - Secure communication with Elasticsearch
- **Flexible Authentication** - Supports basic auth with Kubernetes secrets

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Elasticsearch 8.x

## Quick Start

```bash
# Add the Helm repository
helm repo add btungut https://btungut.github.io

# Install with minimal configuration
helm upgrade -i fluentd btungut/fluentd-kube-elastic \
  --set conf.elasticsearch.host=elasticsearch.logging.svc.cluster.local \
  --namespace logging --create-namespace
```

## Installation

### Basic Installation

```bash
helm upgrade -i fluentd btungut/fluentd-kube-elastic \
  --set conf.elasticsearch.host=<ELASTICSEARCH_HOST> \
  --namespace logging
```

### Installation with Authentication

```bash
helm upgrade -i fluentd btungut/fluentd-kube-elastic \
  --set conf.elasticsearch.host=<ELASTICSEARCH_HOST> \
  --set conf.elasticsearch.auth.enabled=true \
  --set conf.elasticsearch.auth.user=elastic \
  --set conf.elasticsearch.auth.password=<PASSWORD> \
  --namespace logging
```

### Installation with Values File

```bash
helm upgrade -i fluentd btungut/fluentd-kube-elastic \
  -f values-production.yaml \
  --namespace logging
```

See [examples/](./examples/) directory for complete configuration examples.

## Uninstalling

```bash
helm uninstall fluentd --namespace logging
```

## Configuration

### Core Parameters

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `kind` | Workload type: `Deployment` or `DaemonSet` | `DaemonSet` |
| `image.repository` | Docker image repository | `btungut/fluentd-kube-elastic` |
| `image.tag` | Docker image tag | `1.18-1-rev1` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

### Fluentd Configuration

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `conf.enabled` | Enable default configuration | `true` |
| `conf.debug` | Output to stdout instead of Elasticsearch | `false` |
| `conf.logLevel` | Fluentd log level | `warn` |
| `conf.multilinePattern` | Regex for multiline log detection | See values.yaml |

### Log Filtering

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `conf.allowedNamespaces` | Namespaces to collect logs from (regex) | `[]` (all) |
| `conf.allowedLabels` | Pod labels to filter by (regex, OR logic) | `{}` (all) |
| `conf.ignoredContainersAndNamespaces` | Containers/namespaces to exclude | `[]` |
| `conf.ignoredWords` | Log patterns to exclude | `[]` |
| `conf.removedFields` | Fields to remove from log records | `[]` |

### Elasticsearch Configuration

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `conf.elasticsearch.host` | Elasticsearch host (required) | `""` |
| `conf.elasticsearch.port` | Elasticsearch port | `9200` |
| `conf.elasticsearch.scheme` | Connection scheme (`http`/`https`) | `http` |
| `conf.elasticsearch.indexPrefix` | Index name prefix | `apps` |
| `conf.elasticsearch.auth.enabled` | Enable authentication | `false` |
| `conf.elasticsearch.auth.user` | Username | `elastic` |
| `conf.elasticsearch.auth.password` | Password (plain-text) | `""` |
| `conf.elasticsearch.auth.passwordSecret` | K8s secret with password | `""` |
| `conf.elasticsearch.auth.tlsSecret` | K8s secret with TLS certs | `""` |

### Prometheus Metrics

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `conf.prometheus.enabled` | Enable Prometheus metrics | `false` |
| `conf.prometheus.totalRecordsByImage` | Metric by container image | `true` |
| `conf.prometheus.totalRecordsByNamespace` | Metric by namespace | `true` |

## Examples

### Namespace Filtering

Collect logs only from specific namespaces:

```yaml
conf:
  allowedNamespaces:
    - "production"
    - "staging"
    - "apps-(.*)"  # Regex: matches apps-frontend, apps-backend, etc.
```

### Label-based Filtering

Collect logs only from pods with specific labels (OR logic - any match passes):

```yaml
conf:
  allowedLabels:
    "fluentd.io/collect": "true"
    "app.kubernetes.io/name": "my-app"
```

### Excluding Noisy Logs

Filter out health checks and common noise:

```yaml
conf:
  ignoredWords:
    - "/health"
    - "/healthz"
    - "/readiness"
    - "/liveness"
    - "/metrics"

  ignoredContainersAndNamespaces:
    - "*fluentd*"
    - "*kube-system*"
```

### Production Setup with TLS

```yaml
conf:
  elasticsearch:
    host: "elasticsearch.logging.svc.cluster.local"
    scheme: "https"
    auth:
      enabled: true
      user: "elastic"
      passwordSecret: "elasticsearch-credentials"  # Must contain ELASTICSEARCH_PASSWORD key
      tlsSecret: "elasticsearch-tls"               # Must contain ca.crt, tls.crt, tls.key
```

See [`examples/`](./examples/) directory for complete configuration files:

- [`values-minimal.yaml`](./examples/values-minimal.yaml) - Bare minimum configuration
- [`values-production.yaml`](./examples/values-production.yaml) - Production-ready setup
- [`values-filtered.yaml`](./examples/values-filtered.yaml) - Namespace and label filtering
- [`values-multi-instance.yaml`](./examples/values-multi-instance.yaml) - Multi-instance deployment

## How It Works

### Log Processing Pipeline

1. **Collection** - Tails container log files from `/var/log/containers/`
2. **Format Detection** - Identifies JSON vs plain-text logs
3. **Parsing** - Parses JSON logs, aggregates multiline plain-text logs
4. **Enrichment** - Adds Kubernetes metadata (namespace, pod, labels)
5. **Filtering** - Applies namespace, label, and pattern filters
6. **Output** - Ships to Elasticsearch with configurable buffering

### Sample Log Entry

**Input (stdout):**

```json
{"@timestamp":"2024-12-27T01:42:33.726Z","@level":"debug","@msg":"Request processed","@app":{"name":"API"}}
```

**Output (Elasticsearch):**

```json
{
  "_source": {
    "stream": "stdout",
    "obj": {
      "@timestamp": "2024-12-27T01:42:33.726Z",
      "@level": "debug",
      "@msg": "Request processed",
      "@app": { "name": "API" }
    },
    "kubernetes": {
      "namespace_name": "production",
      "pod_name": "api-589d775b75-s7h8h",
      "container_image": "myregistry/api:v1.0.0",
      "labels": {
        "app.kubernetes.io/name": "api"
      }
    },
    "@timestamp": "2024-12-27T01:42:33.734Z"
  }
}
```

### Kibana Screenshot

![Parsed log entry in Kibana](./.images/kibana-01.png)

## Troubleshooting

### Logs Not Appearing in Elasticsearch

1. Check Fluentd pod logs:

   ```bash
   kubectl logs -l app.kubernetes.io/name=fluentd-kube-elastic -n logging
   ```

2. Enable debug mode:

   ```yaml
   conf:
     debug: true
     logLevel: debug
   ```

3. Verify Elasticsearch connectivity:

   ```bash
   kubectl exec -it <fluentd-pod> -n logging -- curl -v http://<es-host>:9200
   ```

### High Memory Usage

Adjust buffer settings in `conf.elasticsearch.additionalOptions`:

```yaml
additionalOptions: |
  <buffer>
    chunk_limit_size 4m
    total_limit_size 64MB
  </buffer>
```

### Logs Being Filtered Unexpectedly

Check your filter configuration:

- `allowedNamespaces` - Empty means all namespaces allowed
- `allowedLabels` - Empty means all labels allowed
- `ignoredContainersAndNamespaces` - Check for overly broad patterns

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Maintainers

- **Burak Tungut** - [GitHub](https://github.com/btungut)
