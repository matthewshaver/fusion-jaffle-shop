select
    order_total_cents,
    sum(order_total_cents) as total_amount
from {{ ref('stg_orders')}}
group by 1
having total_amount < 0
