
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    (SELECT AVG(total_sales) FROM customer_sales) AS avg_sales,
    DATE_TRUNC('MONTH', d.d_date) AS month,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk IN (
        SELECT i.i_item_sk 
        FROM item i 
        WHERE i.i_current_price > 30.00
    ) AND ss.ss_sold_date_sk = d.d_date_sk) AS high_value_sales_count
FROM 
    top_customers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws)
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC
