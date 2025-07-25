
-- KAFKA CONSUMER FOR VALUES
CREATE TABLE IF NOT EXISTS kafka_messages
(
    message     String
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list      = 'kafka:9092',
    kafka_topic_list       = 'timepush-data',
    kafka_group_name       = 'timepush-group',
    kafka_format           = 'JSONAsString',
    kafka_num_consumers    = 1;

-- KAFKA CONSUMER FOR ERRORS
CREATE TABLE IF NOT EXISTS kafka_errors
(
    occurred_at     String,
    payload         String,
    description     String,
    data_source_id   UUID
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list      = 'kafka:9092',
    kafka_topic_list       = 'timepush-error',
    kafka_group_name       = 'timepush-group',
    kafka_format           = 'JSONEachRow',
    kafka_num_consumers    = 1;

-- TABLE TO STORE ERRORS
CREATE TABLE IF NOT EXISTS errors
(
    occurred_at     DATETIME,
    payload         String,
    description     String,
    data_source_id   UUID
)
ENGINE = MergeTree
ORDER BY (occurred_at)
TTL occurred_at + INTERVAL 30 DAY DELETE;

-- TABLE TO STORE VALUES
CREATE TABLE raw_values
(
    data_source_id   UUID,
    timestamp       DateTime('UTC'),
    value           Float64,
    is_valid        UInt8,
    inserted_at     DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(inserted_at)
ORDER BY (data_source_id, timestamp)
SETTINGS index_granularity = 8192;

-- MATERIALIZED VIEW TO MOVE KAFKA_ERROR TO ERRORS
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_into_errors
TO errors AS
SELECT
    parseDateTimeBestEffortOrNull(occurred_at)  AS occurred_at,
    payload,
    description,
    data_source_id
FROM kafka_errors;

-- MATERIALIZED VIEW TO MOVE KAFKA_MESSAGES TO RAW_VALUES
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_into_raw_values
TO raw_values AS
SELECT
    toUUIDOrNull(JSONExtractString(message, 'data_source_id'))                   AS data_source_id,
    parseDateTimeBestEffortOrNull(JSONExtractString(message, 'timestamp'))      AS timestamp,
    toFloat64OrNull(JSONExtractString(message, 'value'))                        AS value,
    JSONExtract(message,'is_valid','Nullable(UInt8)')                           AS is_valid
FROM kafka_messages
WHERE data_source_id IS NOT NULL
AND timestamp       IS NOT NULL
AND value           IS NOT NULL
AND is_valid        IS NOT NULL;

-- MATERIALIZED VIEW TO MOVE KAFKA_MESSAGES WITH PARSE ERRORS TO ERRORS
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_parse_failed_into_errors
TO errors AS
SELECT
    now()                                                               AS occurred_at,
    message                                                             AS payload,
    concat(
      'missing or invalid: ',
      arrayStringConcat(
        arrayFilter(x -> x != '',
          [
            if(data_source_id IS NULL,   'data_source_id',    ''),
            if(timestamp IS NULL,       'timestamp',        ''),
            if(value IS NULL,           'value',            ''),
            if(is_valid IS NULL,        'is_valid',         '')
          ]
        ),
        ', '
      )
    )                                                                   AS description,
    data_source_id                                                       AS data_source_id
FROM
(
  SELECT
    message,
    toUUIDOrNull(JSONExtractString(message, 'data_source_id'))                   AS data_source_id,
    parseDateTimeBestEffortOrNull(JSONExtractString(message, 'timestamp'))      AS timestamp,
    toFloat64OrNull(JSONExtractString(message, 'value'))                        AS value,
    JSONExtract(message,'is_valid','Nullable(UInt8)')                           AS is_valid
  FROM kafka_messages
)
WHERE data_source_id IS NULL
OR  timestamp       IS NULL
OR  value           IS NULL
OR is_valid         IS NULL;

-- POSTGRES DATASOURCE META
CREATE OR REPLACE DICTIONARY datasource_meta
(
  data_source_id UUID,
  agg_hour       UInt8,
  agg_day        UInt8,
  agg_year       UInt8
)
PRIMARY KEY data_source_id
SOURCE(POSTGRESQL(
  host     'postgres'
  port     5432
  db       'timepush'
  table    'public.data_source_aggregations_view'
  user     'timepush'
  password 'timepush'
))
LIFETIME(600)
LAYOUT(complex_key_hashed());