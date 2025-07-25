/*─────────────────────────────────────────────────────────────────────────*/
/* 1) Raw Kafka-engine tables                                             */
/*─────────────────────────────────────────────────────────────────────────*/

CREATE TABLE IF NOT EXISTS raw_time_values
(
    message   String
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list      = '${CLICKHOUSE_KAFKA_BROKER}',
    kafka_topic_list       = '${KAFKA_TOPIC_DATA}',
    kafka_group_name       = '${KAFKA_GROUP_NAME}',
    kafka_format           = 'JSONAsString',
    kafka_num_consumers    = 1;


CREATE TABLE IF NOT EXISTS raw_errors
(
    error_time    String,
    raw_message   String,
    error_descr   String,
    datasource_id UUID
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list      = '${CLICKHOUSE_KAFKA_BROKER}',
    kafka_topic_list       = '${KAFKA_TOPIC_ERROR}',
    kafka_group_name       = '${KAFKA_GROUP_NAME}',
    kafka_format           = 'JSONEachRow',
    kafka_num_consumers    = 1;



/*─────────────────────────────────────────────────────────────────────────*/
/* 2) Persistent MergeTree tables                                         */
/*─────────────────────────────────────────────────────────────────────────*/

CREATE TABLE IF NOT EXISTS time_values
(
    datasource_id UUID,
    utcdatetime   DateTime('UTC'),
    value         Float64,
    status        Int32 DEFAULT 0
)
ENGINE = MergeTree
ORDER BY (datasource_id, utcdatetime);


CREATE TABLE IF NOT EXISTS errors
(
    error_time    DateTime,
    raw_message   String,
    error_descr   String,
    datasource_id UUID
)
ENGINE = MergeTree
ORDER BY (error_time)
TTL error_time + INTERVAL ${CLICKHOUSE_ERRORS_TTL_DAYS} DAY DELETE;



/*─────────────────────────────────────────────────────────────────────────*/
/* 3) Materialized Views                                                   */
/*    — Data pipeline → typed table                                       */
/*    — Parse-failure pipeline → errors                                    */
/*    — Error-topic pipeline → errors                                      */
/*─────────────────────────────────────────────────────────────────────────*/

-- 3.1 Ingest good messages into `time_values`
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_into_time_values
TO time_values AS
SELECT
    toUUIDOrNull(JSONExtractString(message, 'datasource_id'))               AS datasource_id,
    parseDateTimeBestEffortOrNull(JSONExtractString(message, 'utcdatetime')) AS utcdatetime,
    toFloat64OrNull(JSONExtractString(message, 'value'))                    AS value,
    coalesce(toInt32OrNull(JSONExtractString(message, 'status')), 0)        AS status
FROM raw_time_values
WHERE
      datasource_id IS NOT NULL
  AND utcdatetime   IS NOT NULL
  AND value         IS NOT NULL
;

-- 3.2 Route parse-failures (missing/invalid fields) into `errors`
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_into_errors
TO errors AS
SELECT
    now()                                                               AS error_time,
    message                                                             AS raw_message,
    concat(
      'missing or invalid: ',
      arrayStringConcat(
        arrayFilter(x -> x != '',
          [
            if(datasource_id IS NULL, 'datasource_id',   ''),
            if(utcdatetime IS NULL,   'timestamp',       ''),
            if(value IS NULL,         'value',           ''),
            if(status IS NULL,        'status',          '')
          ]
        ),
        ', '
      )
    )                                                                   AS error_descr,
    datasource_id
FROM
(
  SELECT
    message,
    toUUIDOrNull(JSONExtractString(message, 'datasource_id'))               AS datasource_id,
    parseDateTimeBestEffortOrNull(JSONExtractString(message, 'utcdatetime')) AS utcdatetime,
    toFloat64OrNull(JSONExtractString(message, 'value'))                    AS value,
    toInt32OrNull(JSONExtractString(message, 'status'))                     AS status
  FROM raw_time_values
)
WHERE
      datasource_id IS NULL
  OR  utcdatetime   IS NULL
  OR  value         IS NULL
;

-- 3.3 Ingest all error-topic messages straight into `errors`
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_error_topic_into_errors
TO errors AS
SELECT
    parseDateTimeBestEffortOrNull(error_time)  AS error_time,
    raw_message,
    error_descr,
    datasource_id
FROM raw_errors
;
