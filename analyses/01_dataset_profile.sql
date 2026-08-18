-- Run in BigQuery or compile with dbt to profile the source dataset.
SELECT
  COUNT(*) AS total_events,
  COUNT(DISTINCT user_pseudo_id) AS distinct_users,
  MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_date,
  MAX(PARSE_DATE('%Y%m%d', event_date)) AS last_date
FROM {{ source('ga4_ecommerce', 'events') }};
