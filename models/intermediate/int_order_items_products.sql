{{
    config(
        materialized='ephemeral'
    )
}}

with

order_items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

supplies as (

    select * from {{ ref('stg_supplies') }}

),

supply_costs_by_product as (

    select
        product_id,
        sum(supply_cost) as supply_cost,
        sum(case when is_perishable_supply then supply_cost else 0 end) as perishable_cost,
        count(*) as supply_count

    from supplies

    group by 1

),

joined as (

    select
        order_items.order_item_id,
        order_items.order_id,
        order_items.product_id,

        products.product_name,
        products.product_type,
        products.product_price,
        products.is_food_item,
        products.is_drink_item,

        supply_costs_by_product.supply_cost,
        supply_costs_by_product.perishable_cost,
        supply_costs_by_product.supply_count,

        products.product_price - supply_costs_by_product.supply_cost as gross_margin

    from order_items

    left join products on order_items.product_id = products.product_id

    left join supply_costs_by_product
        on order_items.product_id = supply_costs_by_product.product_id

)

select * from joined
