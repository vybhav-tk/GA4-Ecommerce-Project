{{
  config(
    materialized = 'view',
    description = 'Base GA4 event record. One row per event.'
  )
}}

/*
  This model reads from the GA4 wildcard table and flattens
  the top-level fields. It does NOT unnest event_params or items.
  Cost saving: we use a date range macro to limit dev runs.
*/

WITH source AS (

  SELECT
    *,
    _TABLE_SUFFIX AS table_date
  FROM {{ source('ga4_ecommerce', 'events') }}

  {% if target.name == 'dev' %}
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
  {% endif %}

),

renamed AS (

  SELECT
    -- Surrogate key
    {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'event_timestamp']) }} AS event_id,

    -- User identifier
    user_pseudo_id,

    -- Event details
    event_name,
    TIMESTAMP_MICROS(event_timestamp)           AS event_timestamp_utc,
    PARSE_DATE('%Y%m%d', event_date)            AS event_date,

    -- Session identifier (constructed from user + session id param)
    CONCAT(
      user_pseudo_id,
      '_',
      CAST(
        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id'
         LIMIT 1)
      AS STRING)
    )                                            AS session_id,

    -- Platform and device
    platform,
    device.category                             AS device_category,
    device.operating_system                     AS device_operating_system,
    device.web_info.browser                     AS device_browser,
    device.mobile_brand_name                    AS device_brand,

    -- Geography
    geo.country                                 AS geo_country,
    geo.region                                  AS geo_region,
    geo.city                                    AS geo_city,

    -- User-level traffic source (first touch)
    traffic_source.source                       AS traffic_source,
    traffic_source.medium                       AS traffic_medium,
    traffic_source.name                         AS traffic_campaign,

    -- Ecommerce fields (populated on purchase events)
    ecommerce.transaction_id,
    ecommerce.purchase_revenue,
    ecommerce.purchase_revenue_in_usd    AS purchase_revenue_usd,
    ecommerce.unique_items

  FROM source

)

SELECT * FROM renamed