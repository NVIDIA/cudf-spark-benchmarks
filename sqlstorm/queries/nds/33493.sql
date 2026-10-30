
WITH  cte_sales AS (
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk) AS sales_rank
    FROM store_sales 
    GROUP BY ss_sold_date_sk, ss_item_sk
), 
cte_returns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns 
    GROUP BY sr_item_sk
),
cte_customer AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_spent
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.order_count,
    c.total_spent,
    COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amt, 0) AS net_sales
FROM cte_customer c
LEFT JOIN (
    SELECT 
        ss_item_sk, 
        SUM(total_sales) AS total_sales
    FROM cte_sales
    WHERE sales_rank = 1
    GROUP BY ss_item_sk
) s ON c.c_customer_sk = s.ss_item_sk
LEFT JOIN cte_returns r ON s.ss_item_sk = r.sr_item_sk
WHERE c.total_spent > 1000
ORDER BY net_sales DESC
LIMIT 10;
