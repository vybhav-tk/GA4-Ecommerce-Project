{{
  config(
    materialized = 'table',
    partition_by = {
      'field': 'interaction_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    cluster_by = ['event_name', 'item_category'],
    description = 'One row per item per product event. Funnel steps 1-4.'
  )
}}

SELECT
  {{ dbt_utils.generate_surrogate_key(['event_id', 'item_id']) }} AS interaction_id,
  event_name,
  funnel_step,
  item_id,
  item_name,
  item_brand,
  item_category,
  item_category_2,
  item_variant,
  price,
  quantity,
  item_revenue                 AS revenue,
  user_pseudo_id,
  session_id,
  event_date                   AS interaction_date,
  event_timestamp_utc          AS interacted_at,
  device_category,
  device_operating_system,
  geo_country,
  traffic_source,
  traffic_medium,
  traffic_campaign
FROM {{ ref('int_ga4__product_events') }}