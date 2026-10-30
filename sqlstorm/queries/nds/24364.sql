
WITH  CTE_Customer AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year,
           ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY c_birth_year DESC) AS rn
    FROM customer
), 
CTE_Sales AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws_order_number) AS orders_count,
           RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS customer_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CTE_Returns AS (
    SELECT sr_customer_sk, 
           COUNT(sr_ticket_number) AS returns_count,
           SUM(sr_return_amt) AS total_returned
    FROM store_returns 
    GROUP BY sr_customer_sk
),
CTE_Analysis AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name,
           COALESCE(cs.total_spent, 0) AS total_spent,
           COALESCE(cs.orders_count, 0) AS orders_count,
           COALESCE(cr.returns_count, 0) AS returns_count,
           COALESCE(cr.total_returned, 0) AS total_returned,
           CASE 
               WHEN COALESCE(cs.total_spent, 0) = 0 THEN 'No Purchases'
               WHEN COALESCE(cr.returns_count, 0) > 0 THEN 'Frequent Returns'
               ELSE 'Regular Customer'
           END AS customer_status
    FROM CTE_Customer c
    LEFT JOIN CTE_Sales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    LEFT JOIN CTE_Returns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT a.c_customer_sk, a.c_first_name, a.c_last_name, 
       a.total_spent, a.orders_count, a.returns_count, a.total_returned,
       CASE 
           WHEN a.orders_count > 5 AND a.total_spent > 1000 THEN 'High Value'
           WHEN a.orders_count BETWEEN 3 AND 5 THEN 'Moderate Value'
           ELSE 'Low Value'
       END AS customer_value,
       DENSE_RANK() OVER (ORDER BY a.total_spent DESC) AS value_rank
FROM CTE_Analysis a
WHERE (a.total_spent IS NOT NULL OR a.returns_count > 0)
  AND a.customer_status <> 'No Purchases'
ORDER BY value_rank, a.total_spent DESC;
