-- STATE TABLES
-- Hourly state table, partitioned by month of period_start
CREATE TABLE raw_agg_hourly_state
(
  data_source_id     UUID,
  period_start       DateTime,
  period_end         DateTime,
  min_state          AggregateFunction(min, Float64),
  max_state          AggregateFunction(max, Float64),
  sum_state          AggregateFunction(sum, Float64),
  count_state        AggregateFunction(count, UInt64),
  covered_secs_state AggregateFunction(sum, Float64)
)
ENGINE = AggregatingMergeTree
PARTITION BY toYYYYMM(period_start)
ORDER BY (data_source_id, period_start);

-- Daily state table, also partitioned by month
CREATE TABLE raw_agg_daily_state
(
  data_source_id     UUID,
  period_start       DateTime,
  period_end         DateTime,
  min_state          AggregateFunction(min, Float64),
  max_state          AggregateFunction(max, Float64),
  sum_state          AggregateFunction(sum, Float64),
  count_state        AggregateFunction(count, UInt64),
  covered_secs_state AggregateFunction(sum, Float64)
)
ENGINE = AggregatingMergeTree
PARTITION BY toYYYYMM(period_start)
ORDER BY (data_source_id, period_start);

-- Yearly state table, partitioned by year
CREATE TABLE raw_agg_yearly_state
(
  data_source_id     UUID,
  period_start       DateTime,
  period_end         DateTime,
  min_state          AggregateFunction(min, Float64),
  max_state          AggregateFunction(max, Float64),
  sum_state          AggregateFunction(sum, Float64),
  count_state        AggregateFunction(count, UInt64),
  covered_secs_state AggregateFunction(sum, Float64)
)
ENGINE = AggregatingMergeTree
PARTITION BY toYear(period_start)
ORDER BY (data_source_id, period_start);


-- MATERIALIZED VIEWS TO POPULATE STATE TABLES
-- Hourly MV
CREATE MATERIALIZED VIEW mv_into_hourly_state
TO raw_agg_hourly_state AS
SELECT
  t.data_source_id,
  h                                  AS period_start,
  h + INTERVAL 1 HOUR                AS period_end,
  minState(t.value)                  AS min_state,
  maxState(t.value)                  AS max_state,
  sumState(t.value)                  AS sum_state,
  countState()                       AS count_state,
  sumState(
    coalesce(
      least(next_ts, h + INTERVAL 1 HOUR)
    - greatest(t.ts, h)
    , 0)
  )                                  AS covered_secs_state
FROM
(
  SELECT
    data_source_id,
    ts,
    value,
    toStartOfHour(ts)               AS h,
    lead(ts) OVER (
      PARTITION BY data_source_id, toStartOfHour(ts)
      ORDER BY ts
    )                                AS next_ts
  FROM raw_values
  WHERE is_valid = 1
) AS t
ANY LEFT JOIN dictionary('datasource_meta') AS dm USING data_source_id
WHERE dm.agg_hour = 1
GROUP BY t.data_source_id, h;

-- Daily MV
CREATE MATERIALIZED VIEW mv_into_daily_state
TO raw_agg_daily_state AS
SELECT
  t.data_source_id,
  d                                  AS period_start,
  d + INTERVAL 1 DAY                 AS period_end,
  minState(t.value)                  AS min_state,
  maxState(t.value)                  AS max_state,
  sumState(t.value)                  AS sum_state,
  countState()                       AS count_state,
  sumState(
    coalesce(
      least(next_ts, d + INTERVAL 1 DAY)
    - greatest(t.ts, d)
    , 0)
  )                                  AS covered_secs_state
FROM
(
  SELECT
    data_source_id,
    ts,
    value,
    toStartOfDay(ts)                AS d,
    lead(ts) OVER (
      PARTITION BY data_source_id, toStartOfDay(ts)
      ORDER BY ts
    )                                AS next_ts
  FROM raw_values
  WHERE is_valid = 1
) AS t
ANY LEFT JOIN dictionary('datasource_meta') AS dm USING data_source_id
WHERE dm.agg_day = 1
GROUP BY t.data_source_id, d;

-- Yearly MV
CREATE MATERIALIZED VIEW mv_into_yearly_state
TO raw_agg_yearly_state AS
SELECT
  t.data_source_id,
  y                                  AS period_start,
  addYears(y,1)                      AS period_end,
  minState(t.value)                  AS min_state,
  maxState(t.value)                  AS max_state,
  sumState(t.value)                  AS sum_state,
  countState()                       AS count_state,
  sumState(
    coalesce(
      least(next_ts, addYears(y,1))
    - greatest(t.ts, y)
    , 0)
  )                                  AS covered_secs_state
FROM
(
  SELECT
    data_source_id,
    ts,
    value,
    toStartOfYear(ts)               AS y,
    lead(ts) OVER (
      PARTITION BY data_source_id, toStartOfYear(ts)
      ORDER BY ts
    )                                AS next_ts
  FROM raw_values
  WHERE is_valid = 1
) AS t
ANY LEFT JOIN dictionary('datasource_meta') AS dm USING data_source_id
WHERE dm.agg_year = 1
GROUP BY t.data_source_id, y;


-- LIGHTWEIGHT VIEWS
-- Hourly view
CREATE VIEW raw_agg_hourly AS
SELECT
  data_source_id,
  period_start,
  period_end,
  finalize(min_state)                            AS min_val,
  finalize(max_state)                            AS max_val,
  finalize(sum_state)   / finalize(count_state) AS avg_val,
  finalize(count_state)                          AS cnt,
  finalize(covered_secs_state) / 3600.0 * 100     AS coverage_pct
FROM raw_agg_hourly_state;

-- Daily view
CREATE VIEW raw_agg_daily AS
SELECT
  data_source_id,
  period_start,
  period_end,
  finalize(min_state)                            AS min_val,
  finalize(max_state)                            AS max_val,
  finalize(sum_state)   / finalize(count_state) AS avg_val,
  finalize(count_state)                          AS cnt,
  finalize(covered_secs_state) / 86400.0 * 100    AS coverage_pct
FROM raw_agg_daily_state;

-- Yearly view
CREATE VIEW raw_agg_yearly AS
SELECT
  data_source_id,
  period_start,
  period_end,
  finalize(min_state)                            AS min_val,
  finalize(max_state)                            AS max_val,
  finalize(sum_state)   / finalize(count_state) AS avg_val,
  finalize(count_state)                          AS cnt,
  finalize(covered_secs_state)
    / toFloat64(dateDiff('second', period_start, period_end)) * 100 AS coverage_pct
FROM raw_agg_yearly_state;
