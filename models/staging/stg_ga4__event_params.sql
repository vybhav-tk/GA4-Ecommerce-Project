{{
  config(
    materialized = 'view',
    description = 'Unnested event parameters. One row per param per event.'
  )
}}

WITH source AS (

  SELECT
    {{ dbt_utils.generate_surrogate_key(['user_pseudo_id', 'event_timestamp']) }} AS event_id,
    event_params
  FROM {{ source('ga4_ecommerce', 'events') }}

  {% if target.name == 'dev' %}
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
  {% endif %}

),

unnested AS (

  SELECT
    event_id,
    param.key                          AS key,
    param.value.string_value           AS value_string,
    param.value.int_value              AS value_int,
    param.value.float_value            AS value_float,
    param.value.double_value           AS value_double,
    COALESCE(
      param.value.string_value,
      CAST(param.value.int_value    AS STRING),
      CAST(param.value.float_value  AS STRING),
      CAST(param.value.double_value AS STRING)
    )                                  AS value
  FROM source,
  UNNEST(event_params) AS param

)

SELECT * FROM unnested