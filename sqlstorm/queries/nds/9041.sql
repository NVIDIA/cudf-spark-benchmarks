
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_online_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_order_count,
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
    WHERE 
        c.c_birth_year >= 1980 AND c.c_birth_year <= 2000
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        total_online_sales,
        total_catalog_sales,
        total_store_sales,
        online_order_count,
        catalog_order_count,
        store_order_count,
        CASE 
            WHEN total_online_sales > total_catalog_sales AND total_online_sales > total_store_sales THEN 'Online'
            WHEN total_catalog_sales > total_online_sales AND total_catalog_sales > total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END AS preferred_channel
    FROM 
        SalesData
)
SELECT 
    preferred_channel,
    COUNT(*) AS channel_count,
    AVG(total_online_sales) AS avg_online_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    SalesSummary
GROUP BY 
    preferred_channel
ORDER BY 
    channel_count DESC;
