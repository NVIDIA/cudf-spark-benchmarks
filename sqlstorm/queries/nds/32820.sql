
WITH  sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk > 6000000
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(sd.ws_order_number) AS total_orders
    FROM customer c
    JOIN sales_data sd ON c.c_customer_sk = sd.ws_order_number
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM customer_sales cs
),
store_sum AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id
),
results AS (
    SELECT 
        tc.c_customer_id,
        tc.total_profit,
        ts.store_profit,
        tc.total_orders,
        CASE 
            WHEN tc.total_profit > 1000 THEN 'High Value'
            WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        CASE 
            WHEN ts.store_profit IS NULL THEN 'No Sales'
            ELSE 'Sales Exist'
        END AS store_status
    FROM top_customers tc
    LEFT JOIN store_sum ts ON tc.total_orders = ts.store_profit
)
SELECT 
    r.c_customer_id,
    r.total_profit,
    r.store_profit,
    r.customer_value,
    r.store_status
FROM results r
WHERE 
    r.store_status = 'Sales Exist' 
    AND r.total_orders > 5
ORDER BY r.total_profit DESC;
