{{
    config(
        materialized='ephemeral'
    )
}}

with

orders as (

    select * from {{ ref('stg_orders') }}

),

order_items as (

    select * from {{ ref('int_order_items_products') }}

),

orders_with_items as (

    select
        orders.order_id,
        orders.customer_id,
        orders.location_id,
        orders.ordered_at,
        orders.subtotal,
        orders.tax_paid,
        orders.order_total,

        sum(order_items.supply_cost) as order_supply_cost,
        sum(order_items.gross_margin) as order_gross_margin,
        count(order_items.order_item_id) as item_count,
        sum(case when order_items.is_food_item then 1 else 0 end) as food_item_count,
        sum(case when order_items.is_drink_item then 1 else 0 end) as drink_item_count

    from orders

    left join order_items on orders.order_id = order_items.order_id

    group by 1, 2, 3, 4, 5, 6, 7

),

customer_history as (

    select
        *,

        row_number() over (
            partition by customer_id
            order by ordered_at asc
        ) as customer_order_number,

        sum(order_total) over (
            partition by customer_id
            order by ordered_at asc
            rows between unbounded preceding and current row
        ) as cumulative_spend,

        avg(order_total) over (
            partition by customer_id
            order by ordered_at asc
            rows between unbounded preceding and current row
        ) as running_avg_order_value,

        lag(ordered_at) over (
            partition by customer_id
            order by ordered_at asc
        ) as previous_order_at

    from orders_with_items

)

select
    *,
    case
        when previous_order_at is null then null
        else {{ dbt.datediff('previous_order_at', 'ordered_at', 'day') }}
    end as days_since_last_order

from customer_history
