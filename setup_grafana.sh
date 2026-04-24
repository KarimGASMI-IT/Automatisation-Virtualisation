#!/bin/bash

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

PROM_URL="http://localhost:9090"
DASHBOARD_NAME="Monitoring Infra Karim"

echo "[1/4] Attente de Grafana..."
until curl -s "$GRAFANA_URL/api/health" >/dev/null; do
  sleep 2
done

echo "[2/4] Création datasource Prometheus..."
curl -s -X POST "$GRAFANA_URL/api/datasources" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\":\"Prometheus\",
    \"type\":\"prometheus\",
    \"url\":\"$PROM_URL\",
    \"access\":\"proxy\",
    \"basicAuth\":false,
    \"isDefault\":true
  }" >/dev/null

echo "[3/4] Création dashboard Grafana..."
cat > /tmp/dashboard.json <<'EOF'
{
  "dashboard": {
    "id": null,
    "uid": "karim-monitoring",
    "title": "Monitoring Infra Karim",
    "timezone": "browser",
    "schemaVersion": 39,
    "version": 1,
    "refresh": "5s",
    "panels": [
      {
        "type": "timeseries",
        "title": "Disponibilité des serveurs",
        "gridPos": {"x":0,"y":0,"w":12,"h":8},
        "targets": [
          {
            "expr": "up{job=\"node_exporters\"}",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "type": "timeseries",
        "title": "RAM disponible",
        "gridPos": {"x":12,"y":0,"w":12,"h":8},
        "targets": [
          {
            "expr": "node_memory_MemAvailable_bytes{job=\"node_exporters\"}",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "type": "timeseries",
        "title": "CPU utilisé",
        "gridPos": {"x":0,"y":8,"w":12,"h":8},
        "targets": [
          {
            "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{job=\"node_exporters\",mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "type": "timeseries",
        "title": "Disque disponible",
        "gridPos": {"x":12,"y":8,"w":12,"h":8},
        "targets": [
          {
            "expr": "node_filesystem_avail_bytes{job=\"node_exporters\",mountpoint=\"/\"}",
            "legendFormat": "{{instance}}"
          }
        ]
      }
    ]
  },
  "overwrite": true
}
EOF

curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/dashboard.json >/dev/null

echo "[4/4] Terminé."
echo "Dashboard disponible ici :"
echo "http://10.1.1.30:3000/d/karim-monitoring"