
WITH  sales_rank AS (
    SELECT ws_item_sk, 
           ws_order_number, 
           ws_sales_price, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as price_rank
    FROM web_sales
), 
customer_stats AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           AVG(ws_sales_price) AS avg_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
popular_items AS (
    SELECT sr.ws_item_sk,
           SUM(sr.ws_sales_price) AS total_sales
    FROM sales_rank sr
    WHERE sr.price_rank <= 10
    GROUP BY sr.ws_item_sk
),
top_customers AS (
    SELECT cs.c_customer_sk,
           cs.total_orders,
           cs.avg_order_value,
           pi.total_sales
    FROM customer_stats cs
    JOIN popular_items pi ON cs.c_customer_sk = pi.ws_item_sk
    ORDER BY cs.avg_order_value DESC
    LIMIT 5
)
SELECT c.c_first_name, 
       c.c_last_name, 
       tc.total_orders, 
       tc.avg_order_value, 
       tc.total_sales
FROM top_customers tc
JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
WHERE c.c_birth_year IS NOT NULL
  AND tc.avg_order_value IS NOT NULL
  AND tc.total_sales > 1000
ORDER BY tc.total_sales DESC;
