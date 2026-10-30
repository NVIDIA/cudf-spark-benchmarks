
WITH  top_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_spent DESC
    LIMIT 10
),
customer_addresses AS (
    SELECT ca.ca_address_sk,
           ca.ca_city,
           ca.ca_state,
           ca.ca_country,
           ca.ca_zip,
           CASE WHEN ca.ca_city IS NULL THEN 'Unknown City' ELSE ca.ca_city END AS safe_city
    FROM customer_address ca
),
sales_summary AS (
    SELECT ss.ss_store_sk,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
)
SELECT tc.c_first_name,
       tc.c_last_name,
       COALESCE(ca.safe_city, 'No Address') AS city,
       cs.total_sales,
       cs.total_profit,
       DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank,
       ROUND(COALESCE(cs.total_profit / NULLIF(cs.total_sales, 0), 0), 2) AS profit_per_sale
FROM top_customers tc
LEFT JOIN customer_addresses ca ON tc.c_customer_sk = ca.ca_address_sk
JOIN sales_summary cs ON ca.ca_address_sk = cs.ss_store_sk
WHERE EXISTS (
    SELECT 1
    FROM reason r
    WHERE r.r_reason_desc NOT LIKE '%Invalid%'
)
ORDER BY tc.total_spent DESC, profit_rank ASC;
