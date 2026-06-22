import pandas as pd


def model(dbt, session):
    """
    Assigns RFM-based segments to customers using Recency, Frequency, and
    Monetary scores. Runs as a Python model in dbt Fusion on supported adapters.
    """

    dbt.config(
        materialized="table",
        packages=["pandas"],
        tags=["python", "segmentation"],
    )

    customers_df = dbt.ref("customers").to_pandas()
    customers_df.columns = customers_df.columns.str.lower()

    customers_df["days_since_last_order"] = (
        pd.Timestamp.now(tz="UTC").normalize().tz_localize(None)
        - pd.to_datetime(customers_df["last_ordered_at"])
    ).dt.days

    def quartile_score(series, ascending=True):
        """Rank-based 1–4 score that handles duplicate values without label errors."""
        ranked = series.rank(pct=True, ascending=ascending, na_option="bottom")
        return pd.cut(
            ranked,
            bins=[0, 0.25, 0.5, 0.75, 1.0],
            labels=[1, 2, 3, 4],
            include_lowest=True,
        ).astype(int)

    # Recency: fewer days since last order = higher score
    customers_df["recency_score"] = quartile_score(
        customers_df["days_since_last_order"].fillna(9999), ascending=False
    )
    # Frequency: more lifetime orders = higher score
    customers_df["frequency_score"] = quartile_score(
        customers_df["count_lifetime_orders"].fillna(0)
    )
    # Monetary: higher lifetime spend = higher score
    customers_df["monetary_score"] = quartile_score(
        customers_df["lifetime_spend"].fillna(0)
    )

    customers_df["rfm_score"] = (
        customers_df["recency_score"].astype(str)
        + customers_df["frequency_score"].astype(str)
        + customers_df["monetary_score"].astype(str)
    )

    def assign_segment(row):
        r = row["recency_score"]
        f = row["frequency_score"]
        m = row["monetary_score"]
        avg = (r + f + m) / 3
        if r >= 4 and f >= 4:
            return "Champions"
        elif r >= 3 and f >= 3:
            return "Loyal Customers"
        elif r >= 4 and f <= 2:
            return "Recent Customers"
        elif r <= 2 and f >= 3 and m >= 3:
            return "At Risk"
        elif avg <= 2:
            return "Lost"
        else:
            return "Potential Loyalists"

    customers_df["customer_segment"] = customers_df.apply(assign_segment, axis=1)

    result = customers_df[
        [
            "customer_id",
            "customer_name",
            "recency_score",
            "frequency_score",
            "monetary_score",
            "rfm_score",
            "customer_segment",
            "days_since_last_order",
            "count_lifetime_orders",
            "lifetime_spend",
        ]
    ]

    # Snowflake stores lowercase DataFrame column names as case-sensitive quoted
    # identifiers, which breaks unquoted references in dbt tests. Uppercase them
    # so Snowflake treats them as standard case-insensitive identifiers.
    result.columns = result.columns.str.upper()

    return result
