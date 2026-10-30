
WITH customer_sales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cs.total_sales,
           cs.order_count
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.sales_rank <= 10
),
average_order_value AS (
    SELECT ws.ws_bill_customer_sk AS c_customer_sk,
           AVG(ws.ws_sales_price) AS avg_order_value
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
order_analysis AS (
    SELECT tc.c_customer_sk,
           tc.c_first_name,
           tc.c_last_name,
           tc.total_sales,
           tc.order_count,
           a.avg_order_value,
           CASE 
               WHEN tc.order_count > 0 THEN tc.total_sales / tc.order_count
               ELSE 0
           END AS sales_per_order
    FROM top_customers tc
    LEFT JOIN average_order_value a ON tc.c_customer_sk = a.c_customer_sk
)
SELECT o.c_first_name || ' ' || o.c_last_name AS full_name,
       o.total_sales,
       o.order_count,
       o.avg_order_value,
       o.sales_per_order,
       CASE 
           WHEN o.avg_order_value IS NULL THEN 'No Order'
           WHEN o.avg_order_value < 100 THEN 'Low Value Customer'
           ELSE 'High Value Customer'
       END AS customer_segment
FROM order_analysis o
WHERE o.total_sales > 200
ORDER BY o.total_sales DESC;
