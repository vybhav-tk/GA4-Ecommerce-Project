{{
  config(
    materialized = 'view',
    description = 'Unnested product items. One row per item per event.'
  )
}}

WITH source AS (

  SELECT
    {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'event_timestamp']) }} AS event_id,
    event_name,
    items
  FROM {{ source('ga4_ecommerce', 'events') }}

  WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')

  {% if target.name == 'dev' %}
    AND _TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
  {% endif %}

),

unnested AS (

  SELECT
    event_id,
    event_name,
    item.item_id,
    item.item_name,
    item.item_brand,
    item.item_category,
    item.item_category2                AS item_category_2,
    item.item_variant,
    item.price,
    item.quantity,
    COALESCE(item.item_revenue, item.price * item.quantity) AS item_revenue
  FROM source,
  UNNEST(items) AS item

)

SELECT * FROM unnested