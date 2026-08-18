"""Generate the date dimension seed used by the dbt project.

Run from anywhere:
    python scripts/generate_dim_date_seed.py
"""

import csv
from datetime import date, timedelta
from pathlib import Path

START_DATE = date(2020, 11, 1)
END_DATE = date(2021, 1, 31)
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "seeds" / "dim_date_seed.csv"


def build_rows():
    rows = []
    current = START_DATE
    while current <= END_DATE:
        rows.append(
            {
                "date_day": current.isoformat(),
                "year": current.year,
                "quarter": (current.month - 1) // 3 + 1,
                "month": current.month,
                "month_name": current.strftime("%B"),
                "week_of_year": int(current.strftime("%W")),
                "day_of_week": current.isoweekday(),
                "day_name": current.strftime("%A"),
                "is_weekend": str(current.isoweekday() >= 6).upper(),
            }
        )
        current += timedelta(days=1)
    return rows


def main():
    rows = build_rows()
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"Written {len(rows)} rows to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
