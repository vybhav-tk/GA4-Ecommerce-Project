# GA4 eCommerce Analytics — BigQuery · dbt · Power BI

> An end-to-end analytics-engineering project that turns ~4.3M raw, nested Google Analytics 4 events into a tested, documented dimensional model and answers three real business questions about acquisition, funnel drop-off, and product performance.

**Stack:** BigQuery · dbt Core · BEAM dimensional modeling · Power BI · SQL · Jinja

---

## TL;DR

Raw GA4 data in BigQuery is event-level and buried in nested arrays — nobody on a business team can use it directly. This project builds the missing analytics layer: a **dbt pipeline** (staging → intermediate → marts) that flattens, cleans, and re-grains the events into a **star schema** (3 facts + 5 dimensions) designed with the **BEAM** methodology, then connects **Power BI** to the final marts. The result is a single source of truth — version-controlled, automatically tested, and self-documenting — that answers acquisition, funnel, and product questions consistently.

**Headline finding:** the biggest funnel leak is product-view → add-to-cart (only **20.5%** of viewers add to cart), and paid search converted *below* free organic traffic — a concrete "reallocate spend" signal.

---

## The business problem

A retailer (the Google Merchandise Store) runs GA4, which auto-exports raw events to BigQuery daily. Three months of data is sitting there and **nobody can use it**:

- **Marketing** wants to know which channels drive revenue.
- **Merchandising/product** wants to know where users abandon and which products underperform.
- **Leadership** wants conversion trends.

Today they either wait on the data team (a bottleneck), write their own SQL against nested tables (inconsistent), or use the GA4 UI (limited). Everyone gets slightly different numbers — there is no single source of truth. **This project is that source of truth.**

### The three questions the project answers
1. **Acquisition** — Which channels bring users, and which of them convert?
2. **Funnel** — At which step do we lose the most users, and does it vary by device?
3. **Product** — Which products generate revenue, and which have interest but low conversion?

Every table and dashboard traces back to one of these.

---

## Why raw GA4 can't go straight into a BI tool

This is the core technical justification for the whole pipeline:

- **It's event-grain**, not session- or order-grain — one row is never "one customer" or "one order."
- **Key data is nested** — `event_params` and `items` are repeated arrays needing `UNNEST`.
- **There is no session table** — sessions are implied by a `ga_session_id` buried in `event_params` and must be reconstructed.
- **There is no product table** — product attributes live inside the `items` array.
- **It's sharded** across 92 daily tables queried via an `events_*` wildcard.

The governing principle: **do the heavy lifting in the warehouse; let the BI layer consume clean, flat, aggregated tables.**

---

## Architecture

```
Raw GA4 events            dbt transformation layers              Star-schema marts        Power BI
(BigQuery public data) →  staging → intermediate → marts    →   3 facts + 5 dims     →   3 dashboards
   4.3M nested events       clean      business      tested,        the single             answers the
   92 daily tables          & flatten  logic         documented     source of truth        3 questions
```

| Stage | Job | Tooling |
|---|---|---|
| Raw GA4 | Source — nested, event-level | BigQuery public dataset |
| BEAM design | Decide *what* to build and *why*, before code | Dimensional modeling (7Ws) |
| dbt build | Transform raw events into the model, in 3 layers | dbt Core + BigQuery |
| Power BI | Visualise the marts | Power BI Desktop |

---

## Dataset

`bigquery-public-data.ga4_obfuscated_sample_ecommerce`

| | |
|---|---|
| Events | 4,295,584 |
| Users | 270,154 |
| Date range | 2020-11-01 → 2021-01-31 (92 days) |
| Grain | one row per **event**, with `event_params` and `items` nested |

"Obfuscated" = some source/medium and user values are privacy-redacted (`<Other>`, `(data deleted)`) — handled as an "unattributed" bucket rather than dropped.

---

## Data modeling — BEAM → star schema

The schema was designed **before any code**, using **BEAM (Business Event Analysis & Modeling)**: model from business events, not from the source's shape. Each event was interrogated with the **7Ws** (Who/What/When/Where/Why → dimensions; How Many → fact measures; How → keys/classification), which produced the column-level mapping directly.

**3 fact tables**

| Fact | Grain (one row =) |
|---|---|
| `fct_purchases` | one completed transaction |
| `fct_product_interactions` | one item per funnel event (view/cart/checkout/purchase) |
| `fct_sessions` | one reconstructed session |

**5 conformed dimensions:** `dim_users`, `dim_products`, `dim_date`, `dim_device`, `dim_traffic_source`.

```
        dim_users     dim_products      dim_date
            │              │               │
   dim_device ── fct_purchases  fct_product_interactions ── dim_traffic_source
            │              │               │
            └──────── fct_sessions ─────────┘
```

A key design decision: the four funnel events share identical dimensions, so they were **consolidated into one `fct_product_interactions` table with a `funnel_step` flag** rather than split into four near-identical tables.

---

## dbt — the three transformation layers

dbt enforces a strict one-directional flow. Each layer reads only from the layer above it.

| Layer | Job | Reads from | Materialised |
|---|---|---|---|
| **Staging** (`stg_ga4__*`) | Flatten arrays, rename, retype. Zero business logic. | Raw source only | Views |
| **Intermediate** (`int_ga4__*`) | Joins, funnel tagging, **session reconstruction** | Staging only | Views |
| **Marts** (`fct_*`, `dim_*`) | Business-ready star schema | Intermediate only | Tables (partitioned by date) |

**Highlighted transformations:**
- **Flattening the nested schema** — dot notation for single structs (`device.category`), `UNNEST` for repeated arrays (`event_params`, `items`).
- **Session reconstruction** (the hardest piece) — GA4 has no session table, so events are grouped on a manufactured `session_id` (`user_pseudo_id` + `ga_session_id`, because the session id alone isn't unique across users) and aggregated: `MIN`/`MAX` timestamps → start/end/duration, `COUNTIF` per event type → per-session counts, `MAX(CASE WHEN purchase…)` → a `converted` flag.
- **Funnel step derivation** — a `CASE` mapping `view_item`→1 … `purchase`→4.
- **Transaction dedup** — `ROW_NUMBER() OVER (PARTITION BY transaction_id …)` guarantees one row per order.
- **Re-graining** — the pipeline moves event-grain data to whatever grain each question needs (item-per-event for the funnel, session for acquisition, transaction for purchases).

---

## Data quality & engineering practices

- **Automated tests** in YAML (`not_null`, `unique`, `accepted_values`) run on every build — this is what makes "everyone gets the same number" true.
- **Cost-aware dev/prod split** — a Jinja conditional limits `dev` runs to one week of data (fast, near-free); `prod` runs the full dataset once. Power BI connects to `prod`.
- **Partitioning** of fact tables by date so queries only scan needed partitions.
- **Self-documenting** — column descriptions live in YAML; `dbt docs generate` builds a searchable docs site and a full **lineage graph** from source to mart.

---

## Dashboards & key findings

*(Screenshots in `dashboards/screenshots/`.)*

### Funnel — the headline
| Step | Users | % of top | Step-to-step |
|---|---|---|---|
| View item | 61,252 | 100% | — |
| Add to cart | 12,545 | 20.5% | 20.5% |
| Begin checkout | 9,715 | 15.9% | 77.4% |
| Purchase | 4,419 | 7.2% | 45.5% |

- **Biggest leak: view → cart** — ~80% of product-viewers never add to cart (a product-detail-page lever).
- **Cart abandonment ≈ 64.8%**, **checkout abandonment ≈ 54.5%** — checkout friction is the second target.

### Acquisition
Organic search is the **volume** engine (most users and revenue) but converts low (~1.2%); referral and a redacted segment convert highest (2–4%). Most notable: **paid search (`cpc`) converted *below* free organic** — a clear budget-reallocation flag. *(Honest caveat: true ROAS needs ad-spend data, which GA4 doesn't natively hold — a documented limitation.)*

### Headline KPIs
270K users · 4,419 buyers · ~7.2% conversion · ~$362K revenue · ~$82 AOV — across a window spanning Black Friday, Cyber Monday, and Christmas (revenue is highly seasonal, not flat).

---

## How to run it

**Prerequisites:** a Google account with BigQuery access (the free Sandbox is enough), Python 3, and dbt Core with the BigQuery adapter (`pip install dbt-bigquery`).

```bash
# 1. Clone
git clone https://github.com/<your-username>/ga4-ecommerce-analytics-dbt.git
cd ga4-ecommerce-analytics-dbt

# 2. Configure your connection (do NOT commit the real file)
cp profiles.example.yml ~/.dbt/profiles.yml   # then edit in your GCP project id

# 3. Install dbt package dependencies (dbt-utils)
dbt deps

# 4. Generate and load the date dimension seed
python scripts/generate_dim_date_seed.py
dbt seed

# 5. Build — dev runs against one week of data
dbt run            # add --target prod for the full 3-month build

# 6. Test
dbt test

# 7. Explore the lineage graph and docs
dbt docs generate && dbt docs serve
```

Then connect Power BI Desktop → **Get Data → Google BigQuery** → the `prod` marts dataset.

---

## Repository structure

```
├── models/
│   ├── staging/         # stg_ga4__events, __event_params, __items  (flatten & clean)
│   ├── intermediate/    # product_events, session_traffic, sessions (business logic)
│   └── marts/           # 3 fact + 5 dimension tables               (star schema)
├── seeds/               # dim_date.csv
├── scripts/             # generate_dim_date_seed.py
├── dashboards/          # .pbix + screenshots
├── docs/                # data_model.md (BEAM), dbt_walkthrough.md, star_schema.png
├── profiles.example.yml # connection template (no secrets)
└── README.md
```

---

## What this project demonstrates

- **SQL & warehouse engineering** — handling deeply nested GA4 data, window functions, re-graining, partitioning.
- **Dimensional modeling** — BEAM/7Ws → a conformed Kimball star schema with explicit, declared grain.
- **Analytics engineering with dbt** — layered models, tests, sources/refs, Jinja, dev/prod cost control, lineage.
- **BI & storytelling** — translating a model into dashboards and a defensible recommendation, not just charts.
- **Analytical judgment** — anchoring to business questions, finding the funnel leak, spotting paid-below-organic, and documenting limitations honestly.

---

## Notes & honesty

This is a **portfolio project built on Google's public B2C sample data** to demonstrate the GA4 → BigQuery → dbt → BI workflow end to end. The modeling and funnel logic transfer directly to a **B2B** context; what would change are the value metrics — reorder/repeat-purchase rate and account-level conversion instead of one-off AOV — and an expectation of different seasonality.

