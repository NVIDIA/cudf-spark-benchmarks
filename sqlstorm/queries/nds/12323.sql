
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.total_transactions,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    customer_sales cs
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE 
    cs.total_sales > 5000
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
