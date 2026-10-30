
WITH  customer_sales AS (
    SELECT c.c_customer_sk AS customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_profit) > 1000
),
top_customers AS (
    SELECT customer_sk, 
           ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM customer_sales
)
SELECT tc.rank,
       tc.customer_sk,
       cs.c_first_name,
       cs.c_last_name,
       COALESCE(sr.total_returns, 0) AS total_returns,
       ROUND(AVG(ws.ws_sales_price), 2) AS avg_sales_price,
       CASE
           WHEN AVG(ws.ws_sales_price) > 50 THEN 'Premium'
           ELSE 'Standard'
       END AS customer_segment
FROM top_customers tc
JOIN customer_sales cs ON tc.customer_sk = cs.customer_sk
LEFT JOIN (
    SELECT sr_customer_sk, COUNT(*) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
) sr ON cs.customer_sk = sr.sr_customer_sk
LEFT JOIN web_sales ws ON cs.customer_sk = ws.ws_ship_customer_sk
WHERE tc.rank <= 10
GROUP BY tc.rank, tc.customer_sk, cs.c_first_name, cs.c_last_name, sr.total_returns
ORDER BY tc.rank;
