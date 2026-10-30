
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid_inc_ship_tax), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
SalesRanks AS (
    SELECT *,
        RANK() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS overall_rank,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN total_web_sales > total_catalog_sales AND total_web_sales > total_store_sales THEN 'Web'
            WHEN total_catalog_sales > total_web_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END ORDER BY total_web_sales + total_catalog_sales + total_store_sales DESC) AS sales_rank_by_channel
    FROM 
        CustomerSales
)
SELECT 
    cs.c_customer_id,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    sr.overall_rank,
    sr.sales_rank_by_channel,
    CASE 
        WHEN sr.overall_rank IS NULL THEN 'No Sales'
        ELSE 'Sales Data Available'
    END AS sales_status,
    CONCAT('Customer ', cs.c_customer_id, ' has sales data for web: ', cs.total_web_sales, ', catalog: ', cs.total_catalog_sales, ', and store: ', cs.total_store_sales) AS sales_summary
FROM 
    CustomerSales cs
JOIN 
    SalesRanks sr ON cs.c_customer_sk = sr.c_customer_sk
WHERE 
    (sr.overall_rank <= 10 OR cs.total_store_sales <= 0)
    AND (sr.sales_rank_by_channel <= 5 OR cs.total_catalog_sales >= 1000)
ORDER BY 
    sr.overall_rank ASC, cs.total_web_sales DESC
LIMIT 25;
