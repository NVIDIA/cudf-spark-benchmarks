
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
), 
SalesRanked AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_sales,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    sr.rank,
    sr.customer_id,
    sr.total_sales,
    sr.total_transactions
FROM 
    SalesRanked sr
WHERE 
    sr.rank <= 10
ORDER BY 
    sr.rank;
