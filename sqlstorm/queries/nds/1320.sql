
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
store_sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
combined_sales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        COALESCE(sss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(sss.total_store_sales, 0)) AS total_combined_sales
    FROM 
        customer_sales cs
    LEFT JOIN 
        store_sales_summary sss ON cs.c_customer_id = sss.c_customer_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.total_combined_sales,
    RANK() OVER (ORDER BY cs.total_combined_sales DESC) AS sales_rank
FROM 
    customer c
JOIN 
    combined_sales cs ON c.c_customer_id = cs.c_customer_id
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') 
    OR (cd.cd_gender = 'M' AND cd.cd_marital_status IS NULL)
ORDER BY 
    cs.total_combined_sales DESC
LIMIT 10;
