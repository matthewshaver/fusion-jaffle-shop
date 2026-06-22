with

locations as (

    select * from {{ ref('stg_locations') }}

),

order_history as (

    select * from {{ ref('int_customer_order_history') }}

),

location_metrics as (

    select
        location_id,

        count(distinct order_id) as total_orders,
        count(distinct customer_id) as unique_customers,
        sum(order_total) as total_revenue,
        sum(tax_paid) as total_tax_collected,
        sum(order_supply_cost) as total_supply_cost,
        sum(order_gross_margin) as total_gross_margin,
        avg(order_total) as avg_order_value,
        avg(order_gross_margin) as avg_gross_margin_per_order,
        min(ordered_at) as first_order_at,
        max(ordered_at) as last_order_at

    from order_history

    group by 1

),

joined as (

    select
        locations.location_id,
        locations.location_name,
        locations.opened_date,
        locations.tax_rate,

        coalesce(location_metrics.total_orders, 0) as total_orders,
        coalesce(location_metrics.unique_customers, 0) as unique_customers,
        coalesce(location_metrics.total_revenue, 0) as total_revenue,
        coalesce(location_metrics.total_tax_collected, 0) as total_tax_collected,
        coalesce(location_metrics.total_supply_cost, 0) as total_supply_cost,
        coalesce(location_metrics.total_gross_margin, 0) as total_gross_margin,
        location_metrics.avg_order_value,
        location_metrics.avg_gross_margin_per_order,
        location_metrics.first_order_at,
        location_metrics.last_order_at,

        case
            when location_metrics.total_revenue > 0
            then location_metrics.total_gross_margin / location_metrics.total_revenue
            else null
        end as gross_margin_pct

    from locations

    left join location_metrics
        on locations.location_id = location_metrics.location_id

)

select * from joined
