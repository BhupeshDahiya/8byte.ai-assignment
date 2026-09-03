#!/bin/bash

set -e

APP_PRIVATE_IP="${app_private_ip}"
SECRET_NAME="${secret_name}"
AWS_REGION="${aws_region}"

yum update -y
yum install -y docker jq awscli-2

systemctl enable docker
systemctl start docker

mkdir -p /opt/monitoring
cd /opt/monitoring

# Install Docker Compose
mkdir -p /usr/local/lib/docker/cli-plugins

curl -SL \
  https://github.com/docker/compose/releases/download/v5.5.0/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Get database credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text)

DB_USER=$(echo "$SECRET" | jq -r .PG_USER)
DB_PASSWORD=$(echo "$SECRET" | jq -r .PG_PASSWORD)
DB_NAME=$(echo "$SECRET" | jq -r .PG_DB)
DB_HOST=$(echo "$SECRET" | jq -r .PG_HOST)

cat > .env <<EOF
DATA_SOURCE_NAME=postgresql://$${DB_USER}:$${DB_PASSWORD}@$${DB_HOST}:5432/$${DB_NAME}?sslmode=require
EOF

chmod 600 .env

# Prometheus configuration
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: prometheus
    static_configs:
      - targets:
          - prometheus:9090

  - job_name: node
    static_configs:
      - targets:
          - node-exporter:9100

  - job_name: postgres
    static_configs:
      - targets:
          - postgres-exporter:9187

  - job_name: application
    metrics_path: /metrics
    static_configs:
      - targets:
          - $${APP_PRIVATE_IP}:3000
EOF

# Loki configuration
cat > loki-config.yml <<'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  replication_factor: 1

  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  filesystem:
    directory: /loki/chunks

limits_config:
  retention_period: 168h
EOF

# Grafana datasource provisioning
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/dashboards

cat > grafana/provisioning/datasources/datasources.yml <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
EOF

# Monitoring stack
cat > docker-compose.yml <<'EOF'
services:

  prometheus:
    image: prom/prometheus:v3.8.0
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.retention.time=7d
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:12.1.0
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin

  loki:
    image: grafana/loki:3.5.5
    container_name: loki
    restart: unless-stopped
    command: -config.file=/etc/loki/config.yml
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/config.yml:ro
      - loki_data:/loki

  node-exporter:
    image: prom/node-exporter:v1.10.2
    container_name: node-exporter
    restart: unless-stopped
    command:
      - --path.rootfs=/host
    volumes:
      - /:/host:ro,rslave
    ports:
      - "9100:9100"

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:v0.17.1
    container_name: postgres-exporter
    restart: unless-stopped
    environment:
      DATA_SOURCE_NAME: $${DATA_SOURCE_NAME}
    ports:
      - "9187:9187"

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
EOF

docker compose config
docker compose up -d