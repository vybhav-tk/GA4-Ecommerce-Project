# Setup and Run Guide

## Prerequisites

- Python 3.12 is a safe match for the recovered environment
- Google Cloud project with BigQuery enabled
- dbt Core + BigQuery adapter
- access to the public BigQuery dataset
- Git

## Local environment

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## BigQuery authentication

Never place the real service-account JSON inside the Git repository. Use `profiles.example.yml` as a template and keep the key at a local path outside the repo.

Set the environment values before running dbt. Example PowerShell session:

```powershell
$env:GCP_PROJECT_ID="your-gcp-project-id"
$env:DBT_BIGQUERY_KEYFILE="C:\secure\path\dbt-service-account.json"
```

Copy the profile template to your dbt profiles directory and name it `profiles.yml`.

## Build sequence

```bash
dbt debug
dbt deps
python scripts/generate_dim_date_seed.py
dbt seed
dbt run
dbt test
```

Only after dev validation passes:

```bash
dbt run --target prod
dbt test --target prod
```

## Documentation

```bash
dbt docs generate
dbt docs serve
```
