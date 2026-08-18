# Data Exploration

## Source

`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

GA4 exports one daily table per date. Querying `events_*` with `_TABLE_SUFFIX` allows controlled scans across the date range.

## What to re-check in BigQuery

Before rebuilding the dbt project, capture the following in your own notes/results:

- total event rows
- distinct `user_pseudo_id` values
- minimum and maximum `event_date`
- event counts by `event_name`
- funnel-stage counts for `view_item`, `add_to_cart`, `begin_checkout`, and `purchase`
- traffic source / medium distribution
- examples of `event_params`
- examples of `items`

## Schema features that matter

- `event_params` is a repeated key/value array; parameters such as session identifiers and engagement metrics are extracted from it.
- `items` is a repeated array; product-event models unnest it to one row per item per event.
- `traffic_source` is a user-level first-touch structure and should not be confused with session-level attribution.
- `event_timestamp` is stored in microseconds and should be converted early in staging.

## Recommended evidence for the portfolio

When you rerun exploration, save a small results table or screenshot showing the source scale and event distribution. Do not commit raw user-level exports.
