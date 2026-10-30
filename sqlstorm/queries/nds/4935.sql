
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.sales_rank,
    CASE 
        WHEN s.sales_rank <= 10 THEN 'Top 10%'
        WHEN s.sales_rank <= 50 THEN 'Top 50%'
        ELSE 'Lower 50%'
    END AS sales_category
FROM 
    SalesSummary s
WHERE 
    s.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
    OR s.total_catalog_sales > (SELECT AVG(total_catalog_sales) FROM CustomerSales)
ORDER BY 
    s.sales_rank
LIMIT 100;
