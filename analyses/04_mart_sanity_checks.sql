-- Adapt the final SELECTs while validating the project.
-- One statement at a time is easiest to run in BigQuery.

-- Session conversion rate
SELECT
  COUNT(*) AS sessions,
  SUM(converted) AS converted_sessions,
  SAFE_DIVIDE(SUM(converted), COUNT(*)) AS session_conversion_rate
FROM {{ ref('fct_sessions') }};

-- Funnel rows by step
SELECT
  funnel_step,
  event_name,
  COUNT(*) AS rows,
  COUNT(DISTINCT session_id) AS sessions
FROM {{ ref('fct_product_interactions') }}
GROUP BY 1, 2
ORDER BY 1;
