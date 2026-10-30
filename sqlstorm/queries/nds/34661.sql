
WITH  sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount
    FROM sales_data sd
    WHERE sd.rank = 1
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
high_value_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM customer_stats cs
    WHERE cs.total_profit > 10000
),
product_inventory AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)

SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    coalesce(tv.total_sales, 0) AS total_sales,
    coalesce(tv.total_discount, 0) AS total_discount,
    pi.total_inventory,
    CASE 
        WHEN hvc.rank IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM customer c
LEFT JOIN top_sales tv ON c.c_customer_sk = tv.ws_item_sk
LEFT JOIN high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
LEFT JOIN product_inventory pi ON tv.ws_item_sk = pi.inv_item_sk
WHERE c.c_current_addr_sk IS NOT NULL
  AND (pi.total_inventory IS NULL OR pi.total_inventory > 50)
ORDER BY total_sales DESC, c.c_last_name ASC;
