
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        ss_cdemo_sk, 
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_cdemo_sk
),
SalesComparison AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        ss.total_store_sales,
        CASE 
            WHEN cs.total_sales IS NULL AND ss.total_store_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales IS NULL THEN 'Store Sales Only'
            WHEN ss.total_store_sales IS NULL THEN 'Online Sales Only'
            ELSE 'Both Sales'
        END AS sales_type
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.ss_cdemo_sk
)
SELECT 
    sales_type, 
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_online_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    SalesComparison
GROUP BY 
    sales_type
HAVING 
    COUNT(*) > 5
ORDER BY 
    customer_count DESC;
