# Power BI Rebuild Plan

Power BI is intentionally rebuilt from scratch so the data model, DAX measures, and visuals can be verified instead of inherited from the archived `.pbix`.

## Before opening Power BI

- run the production dbt build
- run production dbt tests
- document which mart columns are unique keys
- decide the final relationship strategy for device and traffic-source dimensions
- record baseline session, funnel, purchase, and revenue metrics in BigQuery

## Page 1 — Acquisition

Question: **Which channels bring sessions, and which convert?**

Suggested metrics:

- sessions
- converted sessions
- conversion rate
- revenue / purchases where attribution is defensible

Suggested visuals:

- sessions over time by channel
- conversion rate by channel
- sessions vs conversion-rate scatter

## Page 2 — Funnel

Question: **Where is the largest drop-off in the purchase journey?**

Use distinct sessions/users consistently across all stages. Do not mix row counts at item-event grain with user counts without labeling the metric.

Suggested visuals:

- funnel: view → cart → checkout → purchase
- step-to-step conversion/drop-off
- funnel by device category
- weekly overall conversion trend

## Page 3 — Product

Question: **Which products have interest but weak purchase conversion?**

Suggested metrics:

- product-view sessions
- purchase sessions
- view-to-purchase rate
- item revenue on purchase rows

Suggested visuals:

- top products by revenue
- views vs purchase-rate scatter
- category-level comparison

## Portfolio outputs

Commit:

- screenshots (PNG)
- optionally a PDF export
- a short dashboard methodology note

Prefer a published Power BI link or Git LFS for the `.pbix` if it is too large for normal Git tracking.
