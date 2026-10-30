
WITH daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY d.d_date
), ranked_sales AS (
    SELECT 
        d.d_date,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        total_web_orders,
        total_catalog_orders,
        total_store_orders,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        daily_sales d
)

SELECT 
    r.d_date,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.total_web_orders,
    r.total_catalog_orders,
    r.total_store_orders,
    CASE 
        WHEN r.web_sales_rank = 1 THEN 'Top Web Sales'
        ELSE NULL
    END AS web_sales_status,
    CASE 
        WHEN r.catalog_sales_rank = 1 THEN 'Top Catalog Sales'
        ELSE NULL
    END AS catalog_sales_status,
    CASE 
        WHEN r.store_sales_rank = 1 THEN 'Top Store Sales'
        ELSE NULL
    END AS store_sales_status
FROM 
    ranked_sales r
WHERE 
    (r.total_web_sales > 2000 OR r.total_catalog_sales > 2000 OR r.total_store_sales > 2000)
ORDER BY 
    r.d_date DESC;
