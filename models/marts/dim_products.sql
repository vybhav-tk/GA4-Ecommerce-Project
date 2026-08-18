{{
  config(
    materialized = 'table',
    description = 'One row per item_id. Derived from items array across all product events. Most recently observed values used for name and category.'
  )
}}

WITH all_items AS (

  SELECT
    item_id,
    item_name,
    item_brand,
    item_category,
    item_category_2,
    item_variant,
    event_id
  FROM {{ ref('stg_ga4__items') }}
  WHERE item_id IS NOT NULL

),

-- Join to events to get a timestamp for recency ordering
items_with_timestamp AS (

  SELECT
    i.item_id,
    i.item_name,
    i.item_brand,
    i.item_category,
    i.item_category_2,
    i.item_variant,
    e.event_timestamp_utc,
    ROW_NUMBER() OVER (
      PARTITION BY i.item_id
      ORDER BY e.event_timestamp_utc DESC
    ) AS recency_rank
  FROM all_items i
  LEFT JOIN {{ ref('stg_ga4__events') }} e
    ON i.event_id = e.event_id

)

SELECT
  item_id,
  item_name,
  item_brand,
  item_category,
  item_category_2,
  item_variant
FROM items_with_timestamp
WHERE recency_rank = 1