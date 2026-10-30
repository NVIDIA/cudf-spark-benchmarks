
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS total_unique_customers
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk, 
        i.i_item_desc,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        sd.total_discount_amount,
        sd.total_orders,
        sd.total_unique_customers,
        DENSE_RANK() OVER (ORDER BY sd.total_sales_amount DESC) AS sales_rank
    FROM sales_data sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
),
top_customers AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_ship_customer_sk
),
qualified_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        tc.total_profit,
        tc.total_orders AS customer_orders
    FROM top_customers tc
    JOIN customer c ON tc.ws_ship_customer_sk = c.c_customer_sk
    WHERE tc.total_profit > 1000
)
SELECT 
    ts.sales_rank,
    ts.i_item_desc,
    ts.total_quantity_sold,
    ts.total_sales_amount,
    ts.total_discount_amount,
    tc.total_profit AS customer_total_profit,
    tc.customer_orders AS customer_total_orders
FROM top_sales ts
LEFT JOIN qualified_customers tc ON ts.sales_rank = 1
WHERE ts.sales_rank <= 10
ORDER BY ts.total_sales_amount DESC;
