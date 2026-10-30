
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        c_sales.c_customer_sk,
        c_sales.c_first_name,
        c_sales.c_last_name,
        c_sales.total_store_sales + c_sales.total_web_sales AS total_sales,
        RANK() OVER (ORDER BY c_sales.total_store_sales + c_sales.total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales c_sales
),
top_customers AS (
    SELECT 
        * 
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COALESCE((
        SELECT 
            COUNT(DISTINCT cr.cr_order_number)
        FROM 
            catalog_returns cr
        WHERE 
            cr.cr_returning_customer_sk = tc.c_customer_sk
    ), 0) AS total_catalog_returns,
    (CASE 
        WHEN tc.total_sales > 0 THEN 
            ROUND((COALESCE((SELECT SUM(cr.cr_return_amount) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = tc.c_customer_sk), 0) / NULLIF(tc.total_sales, 0)) * 100, 2)
        ELSE 
            0 
     END) AS return_percentage
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
