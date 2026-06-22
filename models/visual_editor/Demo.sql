WITH stg_order_items AS (
  SELECT
    *
  FROM {{ ref('stg_order_items') }}
), stg_orders AS (
  SELECT
    *
  FROM {{ ref('stg_orders') }}
), join_1 AS (
  SELECT
    stg_orders.ORDER_ID,
    stg_orders.CUSTOMER_ID,
    stg_order_items.PRODUCT_ID
  FROM stg_orders
  JOIN stg_order_items
    ON stg_orders.ORDER_ID = stg_order_items.ORDER_ID
), aggregation_1 AS (
  SELECT
    CUSTOMER_ID,
    PRODUCT_ID,
    COUNT(PRODUCT_ID) AS count_PRODUCT_ID
  FROM join_1
  GROUP BY
    CUSTOMER_ID,
    PRODUCT_ID
), order_1 AS (
  SELECT
    *
  FROM aggregation_1
  ORDER BY
    CUSTOMER_ID ASC,
    count_PRODUCT_ID DESC
), filter_1 AS (
  SELECT
    *
  FROM order_1
  WHERE
    count_PRODUCT_ID = 10
)
SELECT
  *
FROM filter_1