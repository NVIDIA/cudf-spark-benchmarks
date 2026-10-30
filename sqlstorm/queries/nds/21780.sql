
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
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
sales_summary AS (
    SELECT 
        cs.c_customer_id AS customer_id,
        COALESCE(total_web_sales, 0) AS web_sales,
        COALESCE(total_catalog_sales, 0) AS catalog_sales,
        COALESCE(total_store_sales, 0) AS store_sales,
        GREATEST(COALESCE(total_web_sales, 0), COALESCE(total_catalog_sales, 0), COALESCE(total_store_sales, 0)) AS max_sales,
        CASE
            WHEN COALESCE(total_web_sales, 0) > 0 AND COALESCE(total_catalog_sales, 0) > 0 THEN 'Both'
            WHEN COALESCE(total_web_sales, 0) > 0 THEN 'Web Only'
            WHEN COALESCE(total_catalog_sales, 0) > 0 THEN 'Catalog Only'
            ELSE 'None'
        END AS sales_channel
    FROM 
        customer_sales cs
),
ranked_summary AS (
    SELECT 
        customer_id,
        web_sales,
        catalog_sales,
        store_sales,
        max_sales,
        sales_channel,
        RANK() OVER (ORDER BY max_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    rs.customer_id,
    rs.web_sales,
    rs.catalog_sales,
    rs.store_sales,
    rs.max_sales,
    rs.sales_channel,
    CASE WHEN sales_rank <= 10 THEN 'Top 10'
         WHEN sales_rank <= 20 THEN 'Top 20'
         ELSE 'Below Top 20' END AS sales_category
FROM 
    ranked_summary rs
WHERE
    (rs.sales_channel = 'Both' OR rs.web_sales > 100) AND 
    (rs.web_sales IS NOT NULL OR rs.catalog_sales IS NOT NULL OR rs.store_sales IS NOT NULL)
ORDER BY 
    rs.max_sales DESC, 
    rs.customer_id ASC
LIMIT 10 OFFSET 5;
