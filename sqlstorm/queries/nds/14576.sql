
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_sales_price) AS total_revenue 
FROM 
    customer c 
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk 
WHERE 
    i.i_current_price > 50 
GROUP BY 
    c.c_first_name, c.c_last_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
