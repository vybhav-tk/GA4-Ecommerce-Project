{{
  config(
    materialized = 'table',
    partition_by = {
      'field': 'session_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    cluster_by = ['session_source', 'device_category'],
    description = 'One row per session. All logic lives in int_ga4__sessions.'
  )
}}

SELECT
  session_id,
  user_pseudo_id,
  session_date,
  session_start_at,
  session_end_at,
  session_duration_seconds,
  session_number,
  session_engaged,
  total_engagement_ms,
  event_count,
  page_view_count,
  product_view_count,
  add_to_cart_count,
  checkout_count,
  purchase_count,
  converted,
  device_category,
  device_operating_system,
  device_browser,
  geo_country,
  session_source,
  session_medium,
  session_campaign,
  traffic_source,
  traffic_medium,
  traffic_campaign
FROM {{ ref('int_ga4__sessions') }}