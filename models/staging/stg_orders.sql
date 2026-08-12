{{ config(materialized='table', catalog_name='horizon_catalog', alias='STG_ORDERS') }}

with

source as (

    select * from {{ source('ecom', 'raw_orders') }}
    where id not like 'HEARTBEAT-%'
    {{ limit_in_dev('ordered_at') }}

),

renamed as (

    select

        ----------  ids
        id as order_id,
        store_id as location_id,
        customer as customer_id,

        ---------- numerics
        subtotal as subtotal_cents,
        tax_paid as tax_paid_cents,
        order_total as order_total_cents,
        {{ cents_to_dollars('subtotal') }} as subtotal,
        {{ cents_to_dollars('tax_paid') }} as tax_paid,
        {{ cents_to_dollars('order_total') }} as order_total,

        ---------- timestamps
        cast({{ dbt.date_trunc('day','ordered_at') }} as timestamp_ntz(6)) as ordered_at

    from source

)

select * from renamed
