{{
  config(
    materialized = 'view',
    description = 'One row per item per product event. Joins events to items. Feeds fct_product_interactions and fct_purchases.'
  )
}}

WITH events AS (

  SELECT
    event_id,
    event_name,
    user_pseudo_id,
    session_id,
    event_date,
    event_timestamp_utc,
    device_category,
    device_operating_system,
    geo_country,
    traffic_source,
    traffic_medium,
    traffic_campaign,
    transaction_id,
    purchase_revenue,
    purchase_revenue_usd,
    unique_items
  FROM {{ ref('stg_ga4__events') }}
  WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')

),

items AS (

  SELECT
    event_id,
    event_name,
    item_id,
    item_name,
    item_brand,
    item_category,
    item_category_2,
    item_variant,
    price,
    quantity,
    item_revenue
  FROM {{ ref('stg_ga4__items') }}

)

SELECT
  e.event_id,
  i.item_id,
  e.event_name,
  CASE e.event_name
    WHEN 'view_item'      THEN 1
    WHEN 'add_to_cart'    THEN 2
    WHEN 'begin_checkout' THEN 3
    WHEN 'purchase'       THEN 4
  END                                   AS funnel_step,
  e.user_pseudo_id,
  e.session_id,
  e.event_date,
  e.event_timestamp_utc,
  i.item_name,
  i.item_brand,
  i.item_category,
  i.item_category_2,
  i.item_variant,
  i.price,
  i.quantity,
  CASE WHEN e.event_name = 'purchase'
    THEN i.item_revenue
    ELSE NULL
  END                                   AS item_revenue,
  e.transaction_id,
  e.purchase_revenue,
  e.purchase_revenue_usd,
  e.unique_items,
  e.device_category,
  e.device_operating_system,
  e.geo_country,
  e.traffic_source,
  e.traffic_medium,
  e.traffic_campaign
FROM events e
INNER JOIN items i ON e.event_id = i.event_id