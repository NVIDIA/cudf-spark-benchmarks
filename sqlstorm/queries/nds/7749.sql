
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
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
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        CASE 
            WHEN total_sales < 1000 THEN 'Low'
            WHEN total_sales < 5000 THEN 'Medium'
            ELSE 'High'
        END AS sales_band,
        COUNT(*) AS customer_count,
        SUM(web_order_count) AS total_web_orders,
        SUM(catalog_order_count) AS total_catalog_orders,
        SUM(store_order_count) AS total_store_orders
    FROM 
        CustomerSales
    GROUP BY 
        sales_band
)
SELECT 
    s.sales_band, 
    s.customer_count,
    s.total_web_orders,
    s.total_catalog_orders,
    s.total_store_orders,
    ROUND((s.total_web_orders + s.total_catalog_orders + s.total_store_orders) * 100.0 / NULLIF(s.customer_count, 0), 2) AS order_ratio
FROM 
    SalesSummary s
ORDER BY 
    sales_band;
