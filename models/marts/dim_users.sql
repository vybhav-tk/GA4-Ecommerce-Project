{{
  config(
    materialized = 'table',
    description = 'One row per user_pseudo_id. Built from first observed event per user.'
  )
}}

WITH first_event_per_user AS (

  SELECT
    user_pseudo_id,
    MIN(event_timestamp_utc)  AS first_visit_at,
    MIN(event_date)           AS first_visit_date
  FROM {{ ref('stg_ga4__events') }}
  GROUP BY user_pseudo_id

),

user_attributes AS (

  -- Take traffic source and LTV from any event row for this user.
  -- These fields are user-level and identical across all events for
  -- a given user_pseudo_id so MAX() safely returns the single value.
  SELECT
    user_pseudo_id,
    MAX(traffic_source)         AS acquisition_source,
    MAX(traffic_medium)         AS acquisition_medium,
    MAX(traffic_campaign)       AS acquisition_campaign,
  FROM {{ ref('stg_ga4__events') }}
  GROUP BY user_pseudo_id

)

SELECT
  f.user_pseudo_id,
  f.first_visit_date,
  f.first_visit_at,
  a.acquisition_source,
  a.acquisition_medium,
  a.acquisition_campaign,
FROM first_event_per_user f
LEFT JOIN user_attributes a
  ON f.user_pseudo_id = a.user_pseudo_id