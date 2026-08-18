# Revalidation Checklist

This checklist is intentionally separate from the polished project narrative. Work through it while replaying the course and delete/close items as you verify them.

## Security and repository hygiene

- [ ] Revoke the old service-account key from the archived project and create a fresh local credential if needed.
- [ ] Confirm no credential JSON appears in Git history.
- [ ] Confirm `.venv/`, `dbt_env/`, `dbt_packages/`, `target/`, and `logs/` are not tracked.
- [ ] Keep the old `.pbix` out of the repository.

## dbt correctness

- [ ] Re-run `dbt debug`.
- [ ] Re-run `dbt deps`.
- [ ] Re-generate and load `dim_date_seed.csv`.
- [ ] Re-run all staging, intermediate, and mart models in dev.
- [ ] Run `dbt test` and resolve every failure.
- [ ] Re-run in prod only after dev tests pass.

## Known recovered-code items to investigate

- [ ] Verify that `event_id` is genuinely unique at event grain. The recovered implementation hashes `user_pseudo_id + event_timestamp`; historical test output showed collisions.
- [ ] Verify `interaction_id` uniqueness after the event-key decision.
- [ ] Deduplicate session-start traffic rows if a session contains more than one `session_start` record.
- [ ] Revisit `dim_device` grain: its key omits `mobile_brand_name` even though that field participates in the selected distinct rows.
- [ ] Align `fct_purchases` documentation with the SQL: the YAML mentions `total_quantity`, but the recovered SQL currently does not output it.
- [ ] Align `dim_users` documentation with the SQL: the YAML mentions user LTV fields, but the recovered SQL currently does not output them.
- [ ] Decide whether device and traffic-source facts should carry surrogate keys before building Power BI relationships.

## Dashboard rebuild

- [ ] Create a new `.pbix`.
- [ ] Connect only to the production marts needed for each question.
- [ ] Build and validate DAX measures.
- [ ] Reconcile dashboard KPIs against BigQuery.
- [ ] Export screenshots/PDF.
- [ ] Replace README placeholders with verified findings.
