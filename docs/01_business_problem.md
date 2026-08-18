# Business Problem

## Scenario

The Google Merchandise Store has GA4 ecommerce events exported to BigQuery. The source contains rich behavioral data, but using the raw export directly creates inconsistent analysis and a dependence on analysts who know the nested schema.

## Business questions

### Q1 — Acquisition
Which traffic channels generate sessions, and which of those sessions convert to purchase?

### Q2 — Funnel
At which stage of the ecommerce journey is the largest drop-off, and how does the pattern vary by device or source?

### Q3 — Product
Which products attract interest, generate purchases and revenue, or show a large gap between views and purchases?

## Design principle

A model, metric, or dashboard visual should have a clear connection to one of the three questions. This keeps the project focused and makes the repository easier to explain in an interview.
