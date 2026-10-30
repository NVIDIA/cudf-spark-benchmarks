
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
