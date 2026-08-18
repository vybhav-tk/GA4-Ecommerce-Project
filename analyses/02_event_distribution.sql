SELECT
  event_name,
  COUNT(*) AS event_rows,
  COUNT(DISTINCT user_pseudo_id) AS distinct_users
FROM {{ source('ga4_ecommerce', 'events') }}
GROUP BY 1
ORDER BY event_rows DESC;
