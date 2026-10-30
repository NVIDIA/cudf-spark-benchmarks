
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        customer c
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),

CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales
    FROM 
        CustomerSales cs
        FULL OUTER JOIN StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.web_sales,
    c.store_sales,
    c.total_sales,
    RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank,
    CASE 
        WHEN c.total_sales > 1000 THEN 'High Value'
        WHEN c.total_sales BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    CombinedSales c
WHERE 
    c.web_sales > 0 OR c.store_sales > 0
ORDER BY 
    c.total_sales DESC
LIMIT 100;
