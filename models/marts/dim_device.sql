{{
  config(
    materialized = 'table',
    description = 'One row per unique device_category, operating_system, browser combination.'
  )
}}

WITH device_combinations AS (

  SELECT DISTINCT
    device_category,
    device_operating_system  AS operating_system,
    device_browser           AS browser,
    device_brand             AS mobile_brand_name
  FROM {{ ref('stg_ga4__events') }}
  WHERE device_category IS NOT NULL

)

SELECT
  {{ dbt_utils.generate_surrogate_key([
      'device_category',
      'operating_system',
      'browser'
  ]) }}                         AS device_key,
  device_category,
  operating_system,
  browser,
  mobile_brand_name
FROM device_combinations