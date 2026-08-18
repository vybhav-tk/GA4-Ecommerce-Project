{{
  config(
    materialized = 'table',
    description = 'One row per calendar date 2020-11-01 to 2021-01-31. Built from dim_date seed.'
  )
}}

SELECT
  CAST(date_day    AS DATE)    AS date_day,
  CAST(year        AS INT64)   AS year,
  CAST(quarter     AS INT64)   AS quarter,
  CAST(month       AS INT64)   AS month,
  month_name,
  CAST(week_of_year AS INT64)  AS week_of_year,
  CAST(day_of_week  AS INT64)  AS day_of_week,
  day_name,
  CAST(is_weekend  AS BOOL)    AS is_weekend
FROM {{ ref('dim_date_seed') }}