
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales
    FROM customer_sales cs
    WHERE cs.total_sales > (
        SELECT AVG(total_sales) 
        FROM customer_sales
    )
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(hvc.total_sales, 0) AS high_sales,
    COUNT(sr.sr_ticket_number) AS store_returns_count,
    COALESCE(hvc.total_sales / NULLIF(COUNT(sr.sr_ticket_number), 0), 0) AS avg_return_value
FROM customer c
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN high_value_customers hvc ON c.c_customer_sk = hvc.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, hvc.total_sales
HAVING COUNT(sr.sr_ticket_number) < 10
ORDER BY high_sales DESC, avg_return_value ASC
LIMIT 50;
