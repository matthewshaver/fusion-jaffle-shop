# docs-cloud

Internal dbt platform test project maintained by the dbt Labs Docs Team. Built on the Jaffle Shop dataset — a fictional restaurant chain — to validate documentation, demonstrate dbt features, and test dbt platform functionality against a realistic project structure.

---

## Project overview

This project runs on Snowflake via dbt platform and uses dbt Fusion (>=1.9.0). It demonstrates a wide range of dbt features including model contracts, the MetricFlow semantic layer, snapshots, source freshness monitoring, exposures, doc blocks, and custom macros.

Data flows from raw source tables through a three-layer architecture:

- **Staging** cleans and renames raw source fields. Models in this layer are views.
- **Intermediate** contains ephemeral models that encapsulate complex business logic before it reaches the marts.
- **Marts** are the consumption-ready tables — materialized as tables, with contracts enforced, grants applied, and docs persisted to the warehouse.

---

## Project structure

```
models/
├── staging/                  # Views over raw source tables
│   ├── __sources.yml         # Source definitions with freshness config
│   ├── stg_customers.sql
│   ├── stg_locations.sql
│   ├── stg_order_items.sql
│   ├── stg_orders.sql
│   ├── stg_products.sql
│   └── stg_supplies.sql
│
├── intermediate/             # Ephemeral models (not materialized)
│   ├── int_customer_order_history.sql   # Window functions: RFM signals, running totals
│   └── int_order_items_products.sql     # Order items joined with products and supply costs
│
└── marts/                    # Materialized tables for consumption
    ├── customers.sql         # Customer dimension with lifetime value metrics
    ├── orders.sql            # Order fact table
    ├── order_items.sql       # Line-item fact table
    ├── products.sql          # Product dimension
    ├── locations.sql         # Store location dimension
    ├── location_performance.sql  # Location-level revenue and margin rollup
    ├── supplies.sql          # Supply cost reference
    ├── metricflow_time_spine.sql         # Daily time spine for MetricFlow
    └── metricflow_time_spine_monthly.sql # Monthly time spine for MetricFlow

snapshots/
└── products_snapshot.sql     # SCD Type 2 snapshot tracking product price/name changes

seeds/
└── discount_config.csv       # Discount tier lookup table (bronze/silver/gold/platinum)

analyses/
└── revenue_analysis.sql      # Monthly revenue breakdown by product category

macros/
├── cents_to_dollars.sql          # Converts integer cent values to decimal dollars
├── generate_schema_name.sql      # Custom schema naming logic (prod vs. non-prod)
├── insert_freshness_heartbeat.sql # Inserts a synthetic row into raw_orders to keep source freshness green
├── limit_in_dev.sql              # Restricts data to the last year in dev environments
├── safe_divide.sql               # Null-safe division
└── validate_sku.sql              # Generic test: validates SKU format (XXX-NNN)

data-tests/                   # Custom singular tests
```

### Source freshness heartbeat

Because the Jaffle Shop dataset is static, `raw_orders` would never receive new data and source freshness checks would always fail. To keep freshness checks meaningful, the `insert_freshness_heartbeat` macro runs as an `on-run-start` hook at the beginning of every job execution. It inserts a single synthetic `$0` order row with `ordered_at = current_timestamp()` into `raw_orders`, using a `WHERE NOT EXISTS` guard to make it idempotent — safe to run multiple times per day without creating duplicate rows. The heartbeat only runs in non-`dev` and non-`ci` targets to avoid polluting test schemas, and staging models filter these rows out with `WHERE id NOT LIKE 'HEARTBEAT-%'` so they never reach downstream models.

---

### Groups and access

Models are organized into three groups defined in `models/groups.yml`:

| Group | Access | Models |
|---|---|---|
| `analytics` | Public | `customers`, `products`, `locations` |
| `finance` | Public | `orders`, `order_items`, `location_performance` |
| `marketing` | Protected | Segmentation-tagged models |

### Semantic layer

Semantic models, metrics, and saved queries are co-located in each mart's `.yml` file. The project defines:

- **Semantic models** on `orders`, `order_items`, `customers`, `products`, `locations`, and `location_performance`
- **Simple, derived, ratio, and cumulative metrics** across revenue, orders, customers, and margin
- **Saved queries** (`order_metrics`, `revenue_metrics`, `location_kpis`) exported as tables

---

## Jobs

### 1. Daily Incremental Build
**Type:** Deploy | **Schedule:** Daily at 6 AM | **Runs even without new commits**

```
dbt build --exclude tag:segmentation
```

The main production build. Runs all models, tests, snapshots, and seeds except segmentation models, which run on their own schedule. The source freshness heartbeat macro runs at the start of every execution to keep freshness checks green.

---

### 2. Hourly Source Freshness Check
**Type:** Deploy | **Schedule:** Every hour | **Runs even without new commits**

```
dbt source freshness
```

Checks all configured sources for freshness. Warns after 24 hours and errors after 48 hours. Notifications are enabled on both warns and failures. `raw_items` is excluded from freshness checks as it is a static reference table.

---

### 3. Weekly Full Refresh
**Type:** Deploy | **Schedule:** Sunday at midnight**

```
dbt build --full-refresh
```

Rebuilds all incremental models from scratch once a week to prevent drift and catch any data quality issues that incremental logic might miss.

---

### 4. Snapshot Job
**Type:** Deploy | **Schedule:** Daily at 5 AM | **Runs even without new commits**

```
dbt snapshot
```

Runs one hour before the daily build to ensure the `products_snapshot` SCD Type 2 table captures any product price or name changes before downstream models consume the latest product data.

---

### 5. Seed Refresh
**Type:** Deploy | **Trigger:** On merge to main

```
dbt seed
dbt build --select state:modified+
```

Re-seeds reference data (e.g. `discount_config`) and rebuilds any models downstream of changes whenever code is merged to main.

---

### 6. Slim CI
**Type:** CI | **Trigger:** Pull request / every commit to PR branch | **Defers to:** Production environment

```
dbt build --select state:modified+ --defer --favor-state
```

Runs only models and tests affected by changes in the PR, deferring unmodified nodes to the production environment. Keeps CI fast without sacrificing coverage.

---

### 7. Marketing Segmentation Refresh
**Type:** Deploy | **Schedule:** Monday at 7 AM | **Runs even without new commits**

```
dbt build --select tag:segmentation+
```

Rebuilds customer segmentation models and everything downstream of them on a weekly cadence, separate from the daily build to avoid unnecessary compute on non-segmentation runs.

---

### 8. Semantic Layer Saved Query Export
**Type:** Deploy | **Schedule:** Daily at 7 AM

```
dbt sl export-all
```

Exports all saved queries defined in the semantic layer to warehouse tables, making MetricFlow results available to BI tools and downstream consumers without requiring live semantic layer queries.

---

### 9. Contract + Data Quality Gate
**Type:** Deploy | **Trigger:** Runs after Daily Incremental Build completes successfully

```
dbt test --select marts
```

Runs all tests scoped to the marts layer after the daily build finishes. Acts as a quality gate — catching contract violations, expression tests, and relationship failures before downstream consumers are impacted.

---

### 10. Monthly Finance Report Prep
**Type:** Deploy | **Schedule:** 1st of each month at 2 AM

```
dbt build --select group:finance --full-refresh
dbt compile --select path:analyses/revenue_analysis.sql
```

Full-refreshes all finance group models and compiles the monthly revenue analysis query at the start of each month, ensuring finance reporting starts from a clean, fully rebuilt state.
