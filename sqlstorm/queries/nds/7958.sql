
WITH customer_sales AS (
    SELECT c.c_customer_id, 
           SUM(ws.ws_net_paid) AS total_sales, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           COUNT(DISTINCT ws.ws_ship_date_sk) AS order_days
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT c.c_customer_id, cs.total_sales, cs.total_orders, cs.order_days,
           ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales AS cs
    JOIN customer AS c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_sales > 1000
)
SELECT tc.c_customer_id, 
       tc.total_sales, 
       tc.total_orders, 
       tc.order_days, 
       ROUND(tc.total_sales / NULLIF(tc.order_days, 0), 2) AS avg_sales_per_day,
       (SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk AND cd_gender = 'F') AS female_customer_count,
       (SELECT COUNT(DISTINCT ws.ws_order_number) FROM web_sales AS ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS customer_order_count
FROM top_customers AS tc
JOIN customer AS c ON tc.c_customer_id = c.c_customer_id
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
