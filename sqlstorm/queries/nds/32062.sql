WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.ss_sales_price,
        s.ss_sold_date_sk,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk DESC) AS rank
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE s.ss_sales_price > (
        SELECT AVG(ss_sales_price) 
        FROM store_sales 
        WHERE ss_customer_sk = c.c_customer_sk
    )
),
top_sales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        SUM(sh.ss_sales_price) AS total_sales,
        COUNT(sh.ss_sales_price) AS total_transactions
    FROM sales_hierarchy sh
    WHERE sh.rank <= 5
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    CASE 
        WHEN t.total_transactions > 0 THEN ROUND(t.total_sales / t.total_transactions, 2)
        ELSE 0
    END AS avg_sales_per_transaction,
    COALESCE(d.d_current_month, 'No Sales') AS current_month_sales
FROM top_sales t
LEFT JOIN date_dim d ON d.d_current_month = 'Y'
WHERE t.total_sales > 1000
ORDER BY t.total_sales DESC;