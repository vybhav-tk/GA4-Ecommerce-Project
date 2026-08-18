# Data Quality and Validation

## Generic dbt tests already present

The recovered YAML includes tests such as:

- `not_null`
- `unique`
- `accepted_values`

## Validation should cover more than model creation

A successful `dbt run` means the relations were created; it does not prove business correctness. Before publishing findings, also check:

- primary-key uniqueness at the declared grain
- session counts and conversion-rate reasonableness
- all expected funnel steps are present
- purchase rows are one per transaction
- date dimension covers the complete analysis window
- no unintended many-to-many BI relationships
- revenue is not duplicated by joining transaction- and item-grain tables

## Suggested reconciliation queries

Use `analyses/` for reproducible exploration and sanity checks, then compare final mart metrics to direct raw-data baselines where possible.
