{{
  config(
    materialized = 'view',
    description = 'Session-level traffic attribution from event_params on session_start events. One row per session.'
  )
}}

WITH session_start_events AS (

  SELECT
    session_id,
    event_id
  FROM {{ ref('stg_ga4__events') }}
  WHERE event_name = 'session_start'

),

session_params AS (

  SELECT
    p.event_id,
    MAX(CASE WHEN p.key = 'source'   THEN p.value_string END) AS session_source,
    MAX(CASE WHEN p.key = 'medium'   THEN p.value_string END) AS session_medium,
    MAX(CASE WHEN p.key = 'campaign' THEN p.value_string END) AS session_campaign
  FROM {{ ref('stg_ga4__event_params') }} p
  WHERE p.key IN ('source', 'medium', 'campaign')
  GROUP BY p.event_id

)

SELECT
  s.session_id,
  COALESCE(p.session_source,   '(direct)') AS session_source,
  COALESCE(p.session_medium,   '(none)')   AS session_medium,
  COALESCE(p.session_campaign, '(none)')   AS session_campaign
FROM session_start_events s
LEFT JOIN session_params p ON s.event_id = p.event_id