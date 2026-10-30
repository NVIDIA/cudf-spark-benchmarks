WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
SalesComparison AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        CASE 
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(ss.total_store_sales, 0) THEN 'Web'
            WHEN COALESCE(cs.total_web_sales, 0) < COALESCE(ss.total_store_sales, 0) THEN 'Store'
            ELSE 'Equal'
        END AS sales_preference
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk IS NOT NULL AND cs.c_customer_sk = ss.s_store_sk
)
SELECT 
    sc.c_first_name,
    sc.c_last_name,
    sc.total_web_sales,
    sc.total_store_sales,
    sc.sales_preference,
    ROW_NUMBER() OVER (PARTITION BY sc.sales_preference ORDER BY sc.total_web_sales DESC) AS ranking
FROM 
    SalesComparison sc
WHERE 
    (sc.sales_preference = 'Web' AND sc.total_web_sales > 1000)
    OR (sc.sales_preference = 'Store' AND sc.total_store_sales > 500)
ORDER BY 
    sc.sales_preference, ranking;