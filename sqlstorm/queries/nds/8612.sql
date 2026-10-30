
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
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
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        customer_sales.*, 
        ROW_NUMBER() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        ROW_NUMBER() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        ROW_NUMBER() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        customer_sales
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.web_order_count,
    r.catalog_order_count,
    r.store_order_count,
    r.web_sales_rank,
    r.catalog_sales_rank,
    r.store_sales_rank
FROM 
    ranked_sales r
JOIN 
    customer c ON r.c_customer_sk = c.c_customer_sk
WHERE 
    r.web_sales_rank <= 10
    OR r.catalog_sales_rank <= 10
    OR r.store_sales_rank <= 10
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC;
