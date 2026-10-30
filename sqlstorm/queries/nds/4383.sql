WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent >= 1000 THEN 'Premium'
            WHEN cs.total_spent >= 500 THEN 'Mid-Tier'
            ELSE 'Budget'
        END AS customer_segment,
        RANK() OVER (PARTITION BY 
                       CASE 
                           WHEN cs.total_spent >= 1000 THEN 'Premium'
                           WHEN cs.total_spent >= 500 THEN 'Mid-Tier'
                           ELSE 'Budget'
                       END 
                     ORDER BY cs.total_spent DESC) as customer_rank
    FROM 
        CustomerSales cs
    INNER JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    h.customer_segment,
    h.customer_rank
FROM 
    HighSpenders h
WHERE 
    h.customer_segment = 'Premium'
    OR (h.customer_segment = 'Mid-Tier' AND h.customer_rank <= 10)
ORDER BY 
    h.total_spent DESC
LIMIT 20;