#!/bin/sh
# wait-for-kafka.sh

set -e

hostport="$1"
shift

host=$(echo "$hostport" | cut -d: -f1)
port=$(echo "$hostport" | cut -d: -f2)

until nc -z "$host" "$port"; do
  echo "Waiting for Kafka at $host:$port..."
  sleep 2
done

exec "$@"