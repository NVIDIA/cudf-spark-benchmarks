
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
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
customer_ranks AS (
    SELECT 
        c.c_customer_id AS customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        customer_sales c
),
top_customers AS (
    SELECT 
        customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        LEAD(total_web_sales, 1, 0) OVER (ORDER BY total_web_sales DESC) AS next_web_sales,
        LEAD(total_catalog_sales, 1, 0) OVER (ORDER BY total_catalog_sales DESC) AS next_catalog_sales,
        LEAD(total_store_sales, 1, 0) OVER (ORDER BY total_store_sales DESC) AS next_store_sales
    FROM 
        customer_ranks
    WHERE 
        web_sales_rank <= 10 OR catalog_sales_rank <= 10 OR store_sales_rank <= 10
)
SELECT 
    customer_id,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    CASE 
        WHEN total_web_sales > next_web_sales THEN 'Decreased'
        WHEN total_web_sales < next_web_sales THEN 'Increased'
        ELSE 'No Change'
    END AS web_sales_trend,
    CASE 
        WHEN total_catalog_sales > next_catalog_sales THEN 'Decreased'
        WHEN total_catalog_sales < next_catalog_sales THEN 'Increased'
        ELSE 'No Change'
    END AS catalog_sales_trend,
    CASE 
        WHEN total_store_sales > next_store_sales THEN 'Decreased'
        WHEN total_store_sales < next_store_sales THEN 'Increased'
        ELSE 'No Change'
    END AS store_sales_trend
FROM 
    top_customers
WHERE 
    (total_web_sales IS NOT NULL OR total_catalog_sales IS NOT NULL OR total_store_sales IS NOT NULL)
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC;
