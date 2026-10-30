
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesAnalytics AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.web_sales_count,
        cs.catalog_sales_count,
        cs.store_sales_count,
        CASE 
            WHEN cs.total_web_sales > cs.total_catalog_sales AND cs.total_web_sales > cs.total_store_sales THEN 'Web Sales Leader'
            WHEN cs.total_catalog_sales > cs.total_web_sales AND cs.total_catalog_sales > cs.total_store_sales THEN 'Catalog Sales Leader'
            WHEN cs.total_store_sales > cs.total_web_sales AND cs.total_store_sales > cs.total_catalog_sales THEN 'Store Sales Leader'
            ELSE 'Equal Sales Performance'
        END AS sales_leader
    FROM 
        CustomerSales cs
)
SELECT 
    sa.sales_leader,
    COUNT(*) AS customer_count,
    AVG(sa.total_web_sales) AS avg_web_sales,
    AVG(sa.total_catalog_sales) AS avg_catalog_sales,
    AVG(sa.total_store_sales) AS avg_store_sales
FROM 
    SalesAnalytics sa
GROUP BY 
    sa.sales_leader
ORDER BY 
    customer_count DESC;
