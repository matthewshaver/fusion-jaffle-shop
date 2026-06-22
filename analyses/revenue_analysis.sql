-- Revenue and margin analysis by month and product category.
-- Not a dbt model — run ad-hoc via `dbt compile` then execute in your warehouse.

with

order_items as (

    select * from {{ ref('order_items') }}

),

orders as (

    select * from {{ ref('orders') }}

),

monthly_category_revenue as (

    select
        {{ dbt.date_trunc('month', 'order_items.ordered_at') }} as month,

        case
            when order_items.is_food_item then 'Food'
            when order_items.is_drink_item then 'Beverage'
            else 'Other'
        end as product_category,

        count(distinct order_items.order_id) as order_count,
        sum(order_items.product_price) as gross_revenue,
        sum(order_items.supply_cost) as total_supply_cost,
        sum(order_items.product_price - order_items.supply_cost) as gross_margin,
        {{ safe_divide('sum(order_items.product_price - order_items.supply_cost)',
                       'sum(order_items.product_price)') }} as gross_margin_pct

    from order_items

    group by 1, 2

)

select
    month,
    product_category,
    order_count,
    gross_revenue,
    total_supply_cost,
    gross_margin,
    gross_margin_pct,
    sum(gross_revenue) over (
        partition by product_category
        order by month
        rows between unbounded preceding and current row
    ) as cumulative_revenue

from monthly_category_revenue

order by month, product_category
