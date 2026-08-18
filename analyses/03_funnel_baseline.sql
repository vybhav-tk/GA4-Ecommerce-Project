SELECT
  event_name,
  COUNT(*) AS event_rows,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM {{ source('ga4_ecommerce', 'events') }}
WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
GROUP BY 1
ORDER BY CASE event_name
  WHEN 'view_item' THEN 1
  WHEN 'add_to_cart' THEN 2
  WHEN 'begin_checkout' THEN 3
  WHEN 'purchase' THEN 4
END;
