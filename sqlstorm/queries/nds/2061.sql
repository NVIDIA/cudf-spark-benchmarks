
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
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) AS total_sales,
        CASE 
            WHEN cs.total_web_sales > cs.total_catalog_sales AND cs.total_web_sales > cs.total_store_sales THEN 'WEB'
            WHEN cs.total_catalog_sales > cs.total_store_sales THEN 'CATALOG'
            ELSE 'STORE'
        END AS preferred_sales_channel
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
),
ranked_sales AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    r.c_customer_id,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.total_sales,
    r.preferred_sales_channel
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
