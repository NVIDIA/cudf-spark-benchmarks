
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_sales, 
        COUNT(ws_order_number) AS total_orders
    FROM web_sales 
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_net_paid, 0)) DESC) AS spending_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.ca_city,
        cs.total_spent,
        cs.orders_count
    FROM customer_sales cs
    WHERE cs.spending_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    tc.total_spent,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Sales'
        WHEN tc.total_spent > 1000 THEN 'High Roller'
        ELSE 'Casual Buyer'
    END AS customer_type,
    (SELECT COUNT(DISTINCT wr_order_number)
     FROM web_returns
     WHERE wr_returning_customer_sk = tc.c_customer_sk) AS returns_count,
    (SELECT AVG(ws_ext_sales_price)
     FROM web_sales
     WHERE ws_item_sk IN (SELECT sd.ws_item_sk FROM sales_data sd WHERE sd.total_sales > 10000)) AS avg_high_sales_item
FROM top_customers tc
ORDER BY tc.total_spent DESC;
