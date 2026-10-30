
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS number_of_transactions,
    ca.ca_city,
    ca.ca_state
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA' AND 
    ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;
