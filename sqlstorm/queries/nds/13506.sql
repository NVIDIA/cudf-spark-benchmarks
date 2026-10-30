
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS number_of_purchases,
    ca.ca_city,
    d.d_year
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, ca.ca_city, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 10;
