### 📦 TimePush Infrastructure

This repository contains the infrastructure stack for the **TimePush** project

---

#### 1. Clone and Setup

```bash
git clone https://github.com/timepush/infrastructure.git
cd infrastructure
```

#### 2. Start Infrastructure

```bash
docker compose build --no-cache
docker compose up -d --build --scale ingest=4
```

#### 3. Stop Everything

```bash
docker compose down
```

#### Hardcoded values

prometheus.yml has hardcoded nginx  
ngingx has hardcoded port 80 and 5000

---

### Environment Configuration

Edit `.env` to change credentials, ports, or service options, including Kafka topic names.

```env

# =====================
# COMMON (used in multiple services)
# =====================
# Used by: kafka, clickhouse, ingest, kafka-init
KAFKA_LISTENER_PORT=9092
# Used by: clickhouse, ingest, kafka-init
KAFKA_BROKER=kafka:${KAFKA_LISTENER_PORT}
# Used by: clickhouse, kafka-init
KAFKA_TOPIC=timepush-data
# Used by: clickhouse, (possibly ingest)
KAFKA_GROUP_NAME=timepush-group
# Used by: postgres, clickhouse
POSTGRES_USER=timepush
POSTGRES_PASSWORD=timepush
POSTGRES_DB=timepush
# Used by: clickhouse, (possibly ingest)
CLICKHOUSE_KAFKA_BROKER=kafka:${KAFKA_LISTENER_PORT}
# Used by: ingest, nginx
INGEST_PORT=5000
# Used by: redis, ingest
REDIS_HOST=redis
REDIS_PORT=6379

# =====================
# POSTGRES (postgres, clickhouse)
# =====================
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}

# =====================
# KAFKA (kafka)
# =====================
KAFKA_BROKER_ID=1
KAFKA_EXTERNAL_PORT=19092
KAFKA_LOCALHOST_PORT=29092
KAFKA_CLIENT_ID=timepush-ingest-api

# =====================
# ZOOKEEPER (zookeeper, kafka)
# =====================
ZOOKEEPER_PORT=2181

# =====================
# CLICKHOUSE (clickhouse)
# =====================
CLICKHOUSE_HTTP_PORT=8123
CLICKHOUSE_TCP_PORT=9000
CLICKHOUSE_ERRORS_TTL_DAYS=30

# =====================
# PROMETHEUS (prometheus)
# =====================
PROM_PORT=9090

# =====================
# GRAFANA (grafana)
# =====================
GRAFANA_PORT=3000

# =====================
# INGEST (ingest, nginx)
# =====================
INGEST_HOST=ingest
INGEST_LOG_LEVEL=error
NODE_ENV=production

```

On startup, the `kafka-init` service will automatically create the topics specified by `KAFKA_TOPIC`.

---

### Volumes

Docker volumes are used to persist data between restarts:

- redis-data:
- pgdata:
- clickhouse-data:
- grafana-data:
- prometheus-data:

To wipe all data:

```bash
docker compose down -v
```
