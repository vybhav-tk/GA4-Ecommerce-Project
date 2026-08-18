{{
  config(
    materialized = 'table',
    description = 'One row per source and medium combination. Includes channel grouping logic.'
  )
}}

WITH source_medium_combinations AS (

  SELECT DISTINCT
    COALESCE(traffic_source, '(direct)') AS source,
    COALESCE(traffic_medium, '(none)')   AS medium
  FROM {{ ref('stg_ga4__events') }}

),

with_channel_grouping AS (

  SELECT
    source,
    medium,
    CASE
      WHEN source = '(direct)'
       AND medium IN ('(none)', '(not set)')
        THEN 'Direct'
      WHEN medium = 'organic'
        THEN 'Organic Search'
      WHEN medium = 'cpc'
        THEN 'Paid Search'
      WHEN medium = 'referral'
        THEN 'Referral'
      WHEN medium = 'email'
        THEN 'Email'
      WHEN medium IN ('social', 'social-network', 'social-media', 'sm', 'social network')
        OR source IN ('facebook.com', 'instagram.com', 'twitter.com', 'linkedin.com',
                      't.co', 'l.facebook.com', 'lnkd.in')
        THEN 'Social'
      ELSE 'Other'
    END AS channel_grouping
  FROM source_medium_combinations

)

SELECT
  {{ dbt_utils.generate_surrogate_key(['source', 'medium']) }} AS traffic_source_key,
  source,
  medium,
  channel_grouping
FROM with_channel_grouping