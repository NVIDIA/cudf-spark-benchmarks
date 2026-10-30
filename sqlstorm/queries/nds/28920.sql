
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    da.ca_city,
    da.ca_state,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date
FROM 
    customer c
JOIN 
    customer_address da ON c.c_current_addr_sk = da.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    da.ca_city LIKE '%York%' 
    AND da.ca_state = 'NY' 
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id, da.ca_city, da.ca_state, c.c_first_name, c.c_last_name
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
