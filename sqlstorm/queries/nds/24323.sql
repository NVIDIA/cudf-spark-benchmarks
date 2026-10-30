
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
SalesData AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_sales
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = CAST(ss.s_store_sk AS STRING)
),
RankedSales AS (
    SELECT 
        ds.*,
        RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
    FROM 
        SalesData ds
)
SELECT 
    ds.c_customer_id,
    ds.web_sales,
    ds.store_sales,
    ds.total_sales,
    CASE 
        WHEN ds.sales_rank <= 10 THEN 'Top Sales'
        WHEN ds.sales_rank <= 20 THEN 'Mid Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RankedSales ds
WHERE 
    (ds.total_sales > 1000 OR ds.total_sales IS NULL)
    AND (ds.total_sales IS NOT NULL OR ds.web_sales <= 50)
ORDER BY 
    ds.total_sales DESC;
