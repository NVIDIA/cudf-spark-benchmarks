
WITH  customer_sales_cte AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    c.first_name,
    c.last_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    CASE 
        WHEN cs.rank IS NULL THEN 'New Customer'
        WHEN COALESCE(cs.total_sales, 0) > 1000 THEN 'Best Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    (SELECT DISTINCT c.c_first_name AS first_name, c.c_last_name AS last_name
     FROM customer c) AS c
LEFT JOIN 
    customer_sales_cte cs ON c.first_name = cs.c_first_name AND c.last_name = cs.c_last_name
WHERE 
    COALESCE(cs.total_sales, 0) < (
        SELECT AVG(total_sales)
        FROM customer_sales_cte
    )
ORDER BY 
    total_sales DESC;
