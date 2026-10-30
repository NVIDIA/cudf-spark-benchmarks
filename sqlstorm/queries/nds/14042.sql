
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS number_of_transactions 
FROM 
    customer AS c 
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk 
WHERE 
    ss.ss_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim AS d 
        WHERE d.d_year = 2023
    ) 
GROUP BY 
    c.c_first_name, 
    c.c_last_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
