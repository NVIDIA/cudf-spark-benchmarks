
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        coalesce(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        coalesce(SUM(ss.ss_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
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
RankedSales AS (
    SELECT 
        c.*,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN total_web_sales > total_store_sales AND total_web_sales > total_catalog_sales THEN 'Web'
            WHEN total_store_sales > total_web_sales AND total_store_sales > total_catalog_sales THEN 'Store'
            ELSE 'Catalog' END 
        ORDER BY total_web_sales + total_catalog_sales + total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    total_web_sales DESC, 
    total_catalog_sales DESC, 
    total_store_sales DESC;
