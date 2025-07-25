#!/bin/sh
set -e

 # Substitute environment variables in the SQL template using sed and run the resulting SQL
export CLICKHOUSE_KAFKA_BROKER KAFKA_TOPIC_DATA KAFKA_TOPIC_ERROR KAFKA_GROUP_NAME

sed \
  -e "s|\${CLICKHOUSE_KAFKA_BROKER}|${CLICKHOUSE_KAFKA_BROKER}|g" \
  -e "s|\${KAFKA_TOPIC_DATA}|${KAFKA_TOPIC_DATA}|g" \
  -e "s|\${KAFKA_TOPIC_ERROR}|${KAFKA_TOPIC_ERROR}|g" \
  -e "s|\${KAFKA_GROUP_NAME}|${KAFKA_GROUP_NAME}|g" \
  /docker-entrypoint-initdb.d/clickhouse-init.template.sql > /docker-entrypoint-initdb.d/clickhouse-init.sql

# Start ClickHouse server
exec /entrypoint.sh
