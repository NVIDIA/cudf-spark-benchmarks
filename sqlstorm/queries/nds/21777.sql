
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesPerformance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
        CASE 
            WHEN (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) = 0 THEN 'No Sales'
            WHEN (cs.total_web_sales > cs.total_catalog_sales AND cs.total_web_sales > cs.total_store_sales) THEN 'Maximum web sales'
            WHEN (cs.total_catalog_sales > cs.total_web_sales AND cs.total_catalog_sales > cs.total_store_sales) THEN 'Maximum catalog sales'
            ELSE 'Maximum store sales' 
        END AS best_channel,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
),
TopSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY best_channel ORDER BY total_sales DESC) AS channel_rank
    FROM 
        SalesPerformance
)
SELECT 
    t.c_customer_sk, 
    t.c_first_name,
    t.c_last_name,
    t.total_web_sales,
    t.total_catalog_sales,
    t.total_store_sales,
    t.total_sales,
    t.best_channel,
    t.sales_rank
FROM 
    TopSales t
WHERE 
    channel_rank <= 5 AND 
    (t.total_sales > 10 OR t.best_channel != 'No Sales')
ORDER BY 
    t.total_sales DESC, 
    t.c_last_name ASC; 
