### 📦 TimePush Infrastructure

This repository contains the shared infrastructure stack for the **TimePush** project, including:

- **Postgres** – metadata storage
- **Redis** – caching / message queuing
- **Kafka + Zookeeper** – high-throughput message streaming
- **Clickhouse** – time-series sensor data storage

---

### 💠 Services

| Service    | Port                        | Notes                            |
| ---------- | --------------------------- | -------------------------------- |
| Postgres   | `5432`                      | Default DB: `timepush`           |
| Redis      | `6379`                      | No auth for local dev            |
| Kafka      | `9092`                      | Plaintext, for local dev         |
| Zookeeper  | `2181`                      | Required for Kafka               |
| Clickhouse | `8123` (HTTP), `9000` (TCP) | Accessible via browser or client |

---

### 🚀 Getting Started

#### 1. Clone and Setup

```bash
git clone https://github.com/timepush/infrastructure.git
cd infrastructure
```

#### 2. Start Infrastructure

```bash
docker compose --env-file .env up -d
```

#### 3. Stop Everything

```bash
docker compose down
```

---

### ⚙️ Environment Configuration

Edit `.env` to change credentials, ports, or service options, including Kafka topic names.

```env
POSTGRES_USER=timepush
POSTGRES_PASSWORD=timepush
POSTGRES_DB=timepush

KAFKA_BROKER_ID=1
KAFKA_LISTENER_PORT=9092
KAFKA_TOPIC_DATA=timepush-data
KAFKA_TOPIC_ERROR=timepush-error

ZOOKEEPER_PORT=2181

CLICKHOUSE_HTTP_PORT=8123
CLICKHOUSE_TCP_PORT=9000


```

On startup, the `kafka-init` service will automatically create the topics specified by `KAFKA_TOPIC_DATA` and `KAFKA_TOPIC_ERROR`.

---

### 📅 Volumes

Docker volumes are used to persist data between restarts:

- `pgdata` → Postgres data
- `clickhouse-data` → Clickhouse data

To wipe all data:

```bash
docker compose down -v
```
