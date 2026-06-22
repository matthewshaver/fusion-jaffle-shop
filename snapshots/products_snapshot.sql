{% snapshot products_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='check',
        check_cols=['product_name', 'product_price', 'product_type', 'product_description'],
        invalidate_hard_deletes=True,
    )
}}

select * from {{ ref('stg_products') }}

{% endsnapshot %}
