
WITH CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(s.ss_ext_sales_price) AS total_spent,
        AVG(s.ss_ext_sales_price) AS avg_spent_per_purchase
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_purchases,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spender_rank
    FROM CustomerStatistics cs
    WHERE cs.total_spent > (
        SELECT AVG(total_spent) FROM CustomerStatistics
    )
),
TopPurchaseTime AS (
    SELECT 
        d.d_date,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
    ORDER BY purchase_count DESC
    LIMIT 1
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_purchases,
    cs.total_spent,
    hp.spender_rank,
    tt.purchase_count AS highest_purchase_day_count
FROM CustomerStatistics cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
JOIN HighSpenders hp ON cs.c_customer_sk = hp.c_customer_sk
CROSS JOIN TopPurchaseTime tt
WHERE c.c_birth_year IS NOT NULL 
AND c.c_birth_month IS NOT NULL 
AND c.c_birth_day IS NOT NULL
AND (c.c_current_addr_sk IS NULL OR c.c_current_addr_sk NOT IN (
    SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_state = 'CA'
))
ORDER BY cs.total_spent DESC;
