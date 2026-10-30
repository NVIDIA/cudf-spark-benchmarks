
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ss.ss_net_paid) AS total_spent,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT cs.c_customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           cs.total_spent,
           cs.total_transactions,
           ROW_NUMBER() OVER (PARTITION BY CASE 
                                               WHEN cs.total_spent > 1000 THEN 'High'
                                               WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
                                               ELSE 'Low'
                                           END 
                               ORDER BY cs.total_spent DESC) AS rank_within_band
    FROM CustomerSales cs
),
StoreSalesSummary AS (
    SELECT ss.ss_store_sk,
           SUM(ss.ss_net_paid) AS store_revenue,
           COUNT(ss.ss_ticket_number) AS transaction_count,
           COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
)
SELECT hs.c_first_name,
       hs.c_last_name,
       COALESCE(ss.store_revenue, 0) AS store_revenue,
       hs.total_spent AS customer_spent,
       ss.unique_customers,
       CASE 
           WHEN ss.transaction_count IS NULL THEN 'No Sales'
           WHEN ss.transaction_count > 10 THEN 'High Activity'
           ELSE 'Low Activity'
       END AS activity_level,
       CASE 
           WHEN hs.rank_within_band = 1 THEN 'Top Tier'
           WHEN hs.rank_within_band <= 3 THEN 'Subtop Tier'
           ELSE 'Not Ranked'
       END AS spending_tier
FROM HighSpenders hs
FULL OUTER JOIN StoreSalesSummary ss ON hs.c_customer_sk = ss.ss_store_sk
WHERE (hs.total_spent IS NOT NULL AND ss.store_revenue > 0)
   OR (hs.total_spent IS NULL AND ss.store_revenue IS NULL)
ORDER BY hs.total_spent DESC NULLS LAST, ss.store_revenue DESC NULLS FIRST
LIMIT 50;
