# dbt Pipeline

## Staging

Models:

- `stg_ga4__events`
- `stg_ga4__event_params`
- `stg_ga4__items`

Responsibilities:

- read the public GA4 source
- convert timestamps/dates
- extract top-level device, geography, traffic, and ecommerce fields
- unnest `event_params`
- unnest `items`
- construct reusable identifiers
- limit development scans by date

## Intermediate

Models:

- `int_ga4__product_events`
- `int_ga4__session_traffic`
- `int_ga4__sessions`

Responsibilities:

- join event and item grains
- map ecommerce events to funnel steps
- extract session-level traffic parameters
- group events into reconstructed sessions
- calculate event counts, engagement, duration, and conversion flags

## Marts

Facts:

- `fct_sessions`
- `fct_product_interactions`
- `fct_purchases`

Dimensions:

- `dim_users`
- `dim_products`
- `dim_date`
- `dim_device`
- `dim_traffic_source`

The fact tables are partitioned by their business date fields. Some dimensions in the recovered implementation read directly from staging/seed models; document the actual lineage rather than claiming every mart reads only from intermediate models.

## Documentation

Schema YAML files define model/column descriptions and generic tests. Generate the lineage graph with:

```bash
dbt docs generate
dbt docs serve
```
