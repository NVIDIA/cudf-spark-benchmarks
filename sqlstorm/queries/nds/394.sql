
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales IS NOT NULL
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(w.w_warehouse_name, 'Not Assigned') AS warehouse_name,
    (SELECT COUNT(*) FROM store s WHERE s.s_city = 'Seattle') AS seattle_store_count
FROM 
    top_customers tc
LEFT JOIN 
    store s ON tc.c_customer_sk = s.s_store_sk
LEFT JOIN 
    warehouse w ON s.s_market_id = w.w_warehouse_sk
WHERE 
    tc.sales_rank <= 10
AND 
    (tc.order_count > 5 OR (tc.order_count = 5 AND tc.total_sales > 1000))
ORDER BY 
    tc.total_sales DESC;
