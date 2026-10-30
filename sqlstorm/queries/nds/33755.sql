WITH  SaleTrends AS (
    SELECT ws_sold_date_sk, 
           SUM(ws_net_paid) AS total_sales,
           EXTRACT(YEAR FROM d_date) AS sale_year,
           DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM d_date) ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales 
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_date >= cast('2002-10-01' as date) - INTERVAL '1 YEAR'
    GROUP BY ws_sold_date_sk, d_date
    HAVING SUM(ws_net_paid) > 100
),
HighRollingCustomers AS (
    SELECT c_customer_sk,
           COUNT(DISTINCT ws_order_number) AS order_count,
           AVG(ws_net_paid) AS avg_spent
    FROM web_sales
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY c_customer_sk
    HAVING COUNT(DISTINCT ws_order_number) > 5
),
CustomerAddress AS (
    SELECT ca.ca_address_sk,
           ca.ca_city,
           ca.ca_state,
           COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS city_rank
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT ca.ca_city,
       ca.ca_state,
       ca.total_spent,
       COUNT(DISTINCT hrc.c_customer_sk) AS high_rolling_customers_count,
       COALESCE(SUM(st.total_sales), 0) AS total_web_sales_last_year
FROM CustomerAddress ca
LEFT JOIN HighRollingCustomers hrc ON hrc.order_count > 10 AND hrc.avg_spent > 200
LEFT JOIN SaleTrends st ON st.sale_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
WHERE ca.city_rank <= 5 OR ca.ca_state IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_zip IS NOT NULL)
GROUP BY ca.ca_city, ca.ca_state, ca.total_spent
ORDER BY ca.total_spent DESC;