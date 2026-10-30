
WITH  customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           c.c_birth_month, c.c_birth_year, 
           cd.cd_dep_count, 
           hd.hd_income_band_sk,
           ROW_NUMBER() OVER (ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_month IS NOT NULL
), 
customer_sales AS (
    SELECT c.c_customer_sk,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid) AS total_spent,
           AVG(ws.ws_net_paid) AS avg_order_value
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
sales_performance AS (
    SELECT ch.c_customer_sk, 
           ch.c_first_name,
           ch.c_last_name,
           ch.c_birth_month,
           ch.c_birth_year,
           ch.cd_dep_count,
           ch.hd_income_band_sk,
           cs.total_orders,
           cs.total_spent,
           cs.avg_order_value,
           CASE 
               WHEN cs.total_spent IS NULL OR cs.total_spent = 0 THEN 'No Sales'
               WHEN cs.total_orders > 10 THEN 'High Value Customer'
               WHEN cs.total_orders BETWEEN 5 AND 10 THEN 'Medium Value Customer'
               ELSE 'Low Value Customer'
           END AS customer_segment
    FROM customer_hierarchy ch
    LEFT JOIN customer_sales cs ON ch.c_customer_sk = cs.c_customer_sk
),
sales_summary AS (
    SELECT customer_segment, 
           COUNT(*) AS customer_count,
           SUM(total_spent) AS total_revenue,
           AVG(avg_order_value) AS average_order_value
    FROM sales_performance
    GROUP BY customer_segment
)
SELECT segment.customer_segment,
       segment.customer_count,
       COALESCE(segment.total_revenue, 0) AS total_revenue,
       COALESCE(segment.average_order_value, 0) AS average_order_value
FROM sales_summary segment
ORDER BY segment.customer_segment;
