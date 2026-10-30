
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
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
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.total_web_sales, 
        c.total_catalog_sales, 
        c.total_store_sales, 
        (c.total_web_sales + c.total_catalog_sales + c.total_store_sales) AS total_sales, 
        ROW_NUMBER() OVER (ORDER BY (c.total_web_sales + c.total_catalog_sales + c.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales c
),
HighSpenders AS (
    SELECT 
        * 
    FROM 
        SalesSummary 
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
)
SELECT 
    hs.c_customer_sk, 
    CONCAT(hs.c_first_name, ' ', hs.c_last_name) AS full_name, 
    hs.total_web_sales,
    hs.total_catalog_sales,
    hs.total_store_sales,
    hs.total_sales,
    CASE 
        WHEN hs.sales_rank <= 10 THEN 'Top 10 Spender'
        ELSE 'Regular Spender'
    END AS spender_category,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = hs.c_customer_sk) AS total_returns
FROM 
    HighSpenders hs
ORDER BY 
    hs.total_sales DESC;
