
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(cs.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND cs.ss_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
