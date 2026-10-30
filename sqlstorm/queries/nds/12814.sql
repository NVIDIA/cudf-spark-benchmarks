
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS number_of_sales,
    d.d_year
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC;
