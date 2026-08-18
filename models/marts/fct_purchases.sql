{{
  config(
    materialized = 'table',
    partition_by = {
      'field': 'purchase_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    cluster_by = ['traffic_source', 'device_category'],
    description = 'One row per purchase transaction. Grain is transaction not item.'
  )
}}

WITH purchase_rows AS (

  SELECT *
  FROM {{ ref('int_ga4__product_events') }}
  WHERE event_name = 'purchase'
    AND transaction_id IS NOT NULL

),

-- One purchase event can theoretically fire more than once for the same
-- transaction_id in GA4. Deduplicate to guarantee one row per transaction.
deduplicated AS (

  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY transaction_id
      ORDER BY event_timestamp_utc
    ) AS row_num
  FROM purchase_rows

)

SELECT
  {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS purchase_id,
  transaction_id,
  user_pseudo_id,
  session_id,
  event_date                  AS purchase_date,
  event_timestamp_utc         AS purchased_at,
  purchase_revenue            AS revenue,
  purchase_revenue_usd        AS revenue_usd,
  unique_items                AS item_count,
  device_category,
  device_operating_system,
  geo_country,
  traffic_source,
  traffic_medium,
  traffic_campaign
FROM deduplicated
WHERE row_num = 1