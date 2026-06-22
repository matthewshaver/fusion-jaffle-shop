WITH stg_order_items AS (
  SELECT
    *
  FROM {{ ref('stg_order_items') }}
), stg_orders AS (
  SELECT
    *
  FROM {{ ref('stg_orders') }}
), join_5a90 AS (
  SELECT
    stg_orders.ORDER_ID,
    stg_orders.CUSTOMER_ID,
    stg_order_items.PRODUCT_ID
  FROM stg_orders
  JOIN stg_order_items
    ON stg_orders.ORDER_ID = stg_order_items.ORDER_ID
), order_1 AS (
  SELECT
    *
  FROM join_5a90
  ORDER BY
    CUSTOMER_ID ASC
)
SELECT
  *
FROM order_1