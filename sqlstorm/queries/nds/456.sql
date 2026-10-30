
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        CASE 
            WHEN cs.total_web_sales IS NULL AND cs.total_catalog_sales IS NULL AND cs.total_store_sales IS NULL THEN 'No Sales'
            ELSE 'Sales Exist'
        END AS sales_status
    FROM 
        customer_sales cs
),
top_customers AS (
    SELECT 
        s.c_customer_id,
        RANK() OVER (ORDER BY (COALESCE(s.total_web_sales, 0) + COALESCE(s.total_catalog_sales, 0) + COALESCE(s.total_store_sales, 0)) DESC) AS rank
    FROM 
        sales_summary s
)
SELECT 
    s.c_customer_id,
    s.total_web_sales,
    s.total_catalog_sales,
    s.total_store_sales,
    s.sales_status,
    t.rank
FROM 
    sales_summary s
LEFT JOIN 
    top_customers t ON s.c_customer_id = t.c_customer_id
WHERE 
    s.sales_status = 'Sales Exist'
ORDER BY 
    t.rank;
