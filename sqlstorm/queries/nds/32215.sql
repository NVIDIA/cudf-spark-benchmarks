
WITH  Customer_Visits AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COUNT(ss.ss_ticket_number) AS total_orders,
           SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Aggregated_Visits AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(SUM(total_orders), 0) AS overall_orders,
           COALESCE(SUM(total_spent), 0) AS overall_spent
    FROM Customer_Visits c
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Ranked_Customers AS (
    SELECT *,
           RANK() OVER (ORDER BY overall_spent DESC) AS customer_rank
    FROM Aggregated_Visits
)
SELECT DISTINCT
       cu.c_first_name,
       cu.c_last_name,
       cu.overall_orders,
       cu.overall_spent,
       cu.customer_rank,
       CASE
           WHEN cu.overall_spent > 500 THEN 'VIP'
           ELSE 'Regular'
       END AS customer_status
FROM Ranked_Customers cu
WHERE cu.customer_rank <= 10
ORDER BY cu.customer_rank;
