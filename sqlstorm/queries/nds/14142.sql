
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    count(ss.ss_ticket_number) AS total_sales,
    sum(ss.ss_sales_price) AS total_revenue
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    total_revenue DESC
LIMIT 100;
