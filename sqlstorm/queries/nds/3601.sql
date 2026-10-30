
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk 
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
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.web_order_count,
        cs.catalog_order_count,
        cs.store_order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    s.c_first_name || ' ' || s.c_last_name AS customer_name,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.web_order_count,
    s.catalog_order_count,
    s.store_order_count,
    CASE 
        WHEN s.total_web_sales > s.total_catalog_sales AND s.total_web_sales > s.total_store_sales THEN 'Web Sales Leading'
        WHEN s.total_catalog_sales > s.total_web_sales AND s.total_catalog_sales > s.total_store_sales THEN 'Catalog Sales Leading'
        WHEN s.total_store_sales > s.total_web_sales AND s.total_store_sales > s.total_catalog_sales THEN 'Store Sales Leading'
        ELSE 'Sales Equal'
    END AS sales_lead_status
FROM 
    SalesSummary s
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.sales_rank;
