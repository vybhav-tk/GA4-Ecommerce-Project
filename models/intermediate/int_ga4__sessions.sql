{{
  config(
    materialized = 'view',
    description = 'One row per reconstructed session. Aggregates event counts and engagement. Joins session-level traffic attribution.'
  )
}}

WITH events AS (

  SELECT
    session_id,
    user_pseudo_id,
    event_id,
    event_name,
    event_date,
    event_timestamp_utc,
    device_category,
    device_operating_system,
    device_browser,
    geo_country,
    traffic_source,
    traffic_medium,
    traffic_campaign
  FROM {{ ref('stg_ga4__events') }}

),

session_level_params AS (

  SELECT
    e.event_id,
    MAX(CASE WHEN p.key = 'ga_session_number'    THEN CAST(p.value_int AS INT64) END) AS session_number,
    MAX(CASE WHEN p.key = 'session_engaged'      THEN CAST(p.value_int AS INT64) END) AS session_engaged,
    MAX(CASE WHEN p.key = 'engagement_time_msec' THEN CAST(p.value_int AS INT64) END) AS engagement_time_msec
  FROM {{ ref('stg_ga4__events') }} e
  LEFT JOIN {{ ref('stg_ga4__event_params') }} p
    ON e.event_id = p.event_id
   AND p.key IN ('ga_session_number', 'session_engaged', 'engagement_time_msec')
  GROUP BY e.event_id

),

events_with_params AS (

  SELECT
    e.session_id,
    e.user_pseudo_id,
    e.event_name,
    e.event_date,
    e.event_timestamp_utc,
    e.device_category,
    e.device_operating_system,
    e.device_browser,
    e.geo_country,
    e.traffic_source,
    e.traffic_medium,
    e.traffic_campaign,
    p.session_number,
    p.session_engaged,
    p.engagement_time_msec
  FROM events e
  LEFT JOIN session_level_params p ON e.event_id = p.event_id

),

aggregated AS (

  SELECT
    session_id,
    user_pseudo_id,
    MIN(event_date)                                             AS session_date,
    MIN(event_timestamp_utc)                                    AS session_start_at,
    MAX(event_timestamp_utc)                                    AS session_end_at,
    MAX(device_category)                                        AS device_category,
    MAX(device_operating_system)                                AS device_operating_system,
    MAX(device_browser)                                         AS device_browser,
    MAX(geo_country)                                            AS geo_country,
    MAX(traffic_source)                                         AS traffic_source,
    MAX(traffic_medium)                                         AS traffic_medium,
    MAX(traffic_campaign)                                       AS traffic_campaign,
    MAX(session_number)                                         AS session_number,
    MAX(session_engaged)                                        AS session_engaged,
    SUM(COALESCE(engagement_time_msec, 0))                      AS total_engagement_ms,
    COUNT(*)                                                    AS event_count,
    COUNTIF(event_name = 'page_view')                           AS page_view_count,
    COUNTIF(event_name = 'view_item')                           AS product_view_count,
    COUNTIF(event_name = 'add_to_cart')                         AS add_to_cart_count,
    COUNTIF(event_name = 'begin_checkout')                      AS checkout_count,
    COUNTIF(event_name = 'purchase')                            AS purchase_count,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END)    AS converted
  FROM events_with_params
  GROUP BY session_id, user_pseudo_id

),

with_duration AS (

  SELECT
    *,
    TIMESTAMP_DIFF(session_end_at, session_start_at, SECOND) AS session_duration_seconds
  FROM aggregated

)

SELECT
  s.*,
  COALESCE(t.session_source,   s.traffic_source)   AS session_source,
  COALESCE(t.session_medium,   s.traffic_medium)   AS session_medium,
  COALESCE(t.session_campaign, s.traffic_campaign) AS session_campaign
FROM with_duration s
LEFT JOIN {{ ref('int_ga4__session_traffic') }} t
  ON s.session_id = t.session_id