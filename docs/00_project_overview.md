# Project Overview

## Objective

Build a business-ready analytics layer over the Google Merchandise Store GA4 public export in BigQuery, then use that layer to answer acquisition, funnel, and product questions in Power BI.

## End-to-end flow

1. Explore the raw GA4 event schema.
2. Define the business events and grains before coding.
3. Flatten and standardize the source in dbt staging models.
4. Reconstruct reusable business logic in intermediate models.
5. Publish fact and dimension marts.
6. Validate model quality with dbt tests and sanity checks.
7. Connect Power BI to the production marts and build question-led dashboards.

## Why the warehouse layer is necessary

GA4's export is optimized for event collection rather than direct BI consumption. Events are spread across date-sharded tables, context is stored in nested records/arrays, sessions are not provided as a ready-made table, and product data lives inside the repeated `items` structure. The dbt project converts that source into stable analytical grains.

## Current scope

Vanna AI is excluded. Power BI will be rebuilt from a clean report so every measure and visual can be re-checked against the marts.
