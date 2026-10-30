
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.sales_count,
        cs.avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    tc.c_customer_id AS customer_id,
    tc.total_sales,
    tc.sales_count,
    tc.avg_sales_price,
    'High Value' AS customer_segment
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
UNION ALL
SELECT 
    c.c_customer_id,
    COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
    0 AS sales_count,
    0 AS avg_sales_price,
    'Low Value' AS customer_segment
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year < 1970
GROUP BY 
    c.c_customer_id
HAVING 
    COALESCE(SUM(ss.ss_ext_sales_price), 0) = 0;
