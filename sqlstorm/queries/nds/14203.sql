
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS number_of_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_city = 'Los Angeles'
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450050
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
